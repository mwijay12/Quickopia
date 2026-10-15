import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import '../models/supermarket_settings_model.dart';

class AiChatMessage {
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final String? suggestedSearch;
  final String? suggestedAddToCart;
  final bool hasAction;
  final bool isFailed;
  final String? retryQuery;

  AiChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.suggestedSearch,
    this.suggestedAddToCart,
    this.hasAction = false,
    this.isFailed = false,
    this.retryQuery,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  // Multi-Turn Session Memory
  final List<AiChatMessage> _conversationHistory = [];
  List<AiChatMessage> get history => List.unmodifiable(_conversationHistory);

  // API key pools loaded from .env (never commit real keys).
  // Configure in mobile/.env:
  //   GROQ_KEYS=key1,key2,...
  //   GEMINI_KEYS=key1,key2,...
  //   OPENROUTER_KEYS=key1,key2,...
  //   ELEVENLABS_KEYS=key1,key2,...
  static List<String> _keysFromEnv(String name) {
    final raw = dotenv.env[name] ?? '';
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<String> get _groqKeys => _keysFromEnv('GROQ_KEYS');

  List<String> get _openRouterKeys => _keysFromEnv('OPENROUTER_KEYS');

  List<String> get _geminiKeys => _keysFromEnv('GEMINI_KEYS');

  List<String> get _elevenLabsKeys => _keysFromEnv('ELEVENLABS_KEYS');

  int _groqIndex = 0;
  int _geminiIndex = 0;
  int _openRouterIndex = 0;
  int _elevenLabsIndex = 0;

  void clearMemory() {
    _conversationHistory.clear();
  }

  /// Builds system context with live supermarket profile & Dar es Salaam operational rules.
  String _buildSystemPrompt(SupermarketSettings settings) {
    return '''
You are the intelligent AI Concierge & Shopping Assistant for "${settings.supermarketName}" located at ${settings.branchAddress}, Dar es Salaam, Tanzania.
Operating Hours: ${settings.operatingHours}.
Support Phone: ${settings.phone}. Support Email: ${settings.email}.
Delivery Coverage: All Dar es Salaam wards (Kinondoni, Ilala, Ubungo, Kigamboni, Temeke). Express 30-min delivery.
Payment Options: Official Lipa Namba (M-Pesa, Tigo Pesa, Airtel Money, HaloPesa) and Bank (NMB, CRDB). Cash on Delivery available for verified shoppers.
Perishable Returns Claim Window: ${settings.returnWindowHours} hours of delivery via in-app Live Support.
Mandatory OTP: A 6-digit confirmation code is generated for courier handoff.

Your personality:
- Warm, polite, exceptionally helpful Tanzanian supermarket expert.
- Fluent in both English and Swahili (respond in the language the user addresses you in).
- Concise, clear, and actionable advice without rambling.
- Write in clean, natural conversational text.
- Do NOT use markdown headers (never use ### or ## or #).
- Do NOT use excessive asterisks (never use **** or **).
- Do NOT mention underlying AI providers, models, or APIs (such as Llama, Groq, OpenRouter, or Gemini). You represent ${settings.supermarketName} directly.
- Use clean bullet points (•) when listing items.

CRITICAL ACTION TAGS:
When you suggest products or answer product requests (e.g. watches, sugar, rice, cooking oil, diapers, milk):
1. Recommend specific items, their typical price in TZS, and pack sizes.
2. Include the tag: [SEARCH: <concise search keyword>] so the app can instantly render interactive product cards for the customer! Example: [SEARCH: watch] or [SEARCH: sugar] or [SEARCH: rice].
3. If the user explicitly asks you to add an item to their cart, output: [ADD_TO_CART: <item name>].
4. If the user asks about tracking an order, output: [TRACK_ORDER].
Always keep the tag at the very end of your message.
''';
  }

  /// Sends a message, maintains conversation memory, and auto-rotates across Groq -> Gemini -> OpenRouter
  /// with automatic reconnection and retry logic resilient to intermittent cellular networks.
  Future<AiChatMessage> sendMessage({
    required String userMessage,
    required SupermarketSettings settings,
    void Function(String status)? onStatusUpdate,
  }) async {
    // 1. Record user message in memory
    final userChat = AiChatMessage(role: 'user', content: userMessage.trim());
    _conversationHistory.add(userChat);

    final systemPrompt = _buildSystemPrompt(settings);

    // Prepare message payload including recent multi-turn history (up to last 10 messages)
    final messagesPayload = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    final recent = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;

    for (final m in recent) {
      messagesPayload.add({'role': m.role, 'content': m.content});
    }

    String? responseText;
    const int maxAttempts = 3;

    // Multi-attempt reconnection loop with exponential backoff for shaky cellular signals
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt == 1) {
        onStatusUpdate?.call('AI Concierge is connecting...');
      } else {
        onStatusUpdate?.call('Reconnecting to AI network (Attempt $attempt/$maxAttempts)... Inajaribu kuunganisha tena...');
        await Future.delayed(Duration(milliseconds: 1200 * (attempt - 1)));
      }

      try {
        // 1. Try Supabase Edge AI Function first (Server-side key security)
        if (SupabaseConfig.isConfigured) {
          try {
            final res = await SupabaseConfig.client.functions.invoke(
              'ai-assistant',
              body: {
                'message': userMessage,
                'history': recent.map((m) => {'role': m.role, 'content': m.content}).toList(),
                'settings': {
                  'supermarketName': settings.supermarketName,
                  'branchAddress': settings.branchAddress,
                  'operatingHours': settings.operatingHours,
                  'phone': settings.phone,
                  'email': settings.email,
                  'returnWindowHours': settings.returnWindowHours,
                },
              },
            ).timeout(const Duration(seconds: 22));

            if (res.status == 200 && res.data is Map) {
              final reply = res.data['reply'] as String?;
              if (reply != null && reply.trim().isNotEmpty) {
                responseText = reply;
                break;
              }
            }
          } catch (e) {
            debugPrint('Edge AI proxy attempt: $e');
          }
        }

        // 2. Fallback to direct client pools if configured locally (offline / dev)
        responseText = await _tryGroqPool(messagesPayload);

        // 3. Fallback to Gemini 15-Key Pool (Google gemini-flash-latest / gemini-3.6-flash)
        if (responseText == null || responseText.trim().isEmpty) {
          responseText = await _tryGeminiPool(messagesPayload, systemPrompt);
        }

        // 4. Fallback to OpenRouter Free Pool if Gemini fails
        if (responseText == null || responseText.trim().isEmpty) {
          responseText = await _tryOpenRouterPool(messagesPayload);
        }

        if (responseText != null && responseText.trim().isNotEmpty) {
          // Successfully retrieved response from AI network
          break;
        }
      } catch (e) {
        debugPrint('AI connection network hiccup on attempt $attempt: $e');
      }
    }

    final bool isFailed = responseText == null || responseText.trim().isEmpty;

    // Graceful fallback message if all reconnection cycles fail due to complete signal loss
    if (isFailed) {
      responseText =
          'Samahani, mtandao ulikatika wakati wa kuunganisha na AI Concierge. Tafadhali hakikisha simu imeunganishwa kwenye intaneti kisha bonyeza "Jaribu Tena" (Tap to Reconnect & Retry).';
    }

    // 5. Parse action tags from AI output
    String? searchAction;
    String? addToCartAction;

    final searchMatch = RegExp(r'\[SEARCH:\s*([^\]]+)\]', caseSensitive: false).firstMatch(responseText);
    if (searchMatch != null && searchMatch.groupCount >= 1) {
      searchAction = searchMatch.group(1)?.trim();
    }

    final addMatch = RegExp(r'\[ADD_TO_CART:\s*([^\]]+)\]', caseSensitive: false).firstMatch(responseText);
    if (addMatch != null && addMatch.groupCount >= 1) {
      addToCartAction = addMatch.group(1)?.trim();
    }

    // Clean tags and raw markdown headers/asterisks from displayed content
    final cleanContent = responseText
        .replaceAll(RegExp(r'\[SEARCH:[^\]]+\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[ADD_TO_CART:[^\]]+\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[TRACK_ORDER\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*{2,}'), '')
        .replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '• ')
        .trim();

    final assistantMsg = AiChatMessage(
      role: 'assistant',
      content: cleanContent,
      suggestedSearch: searchAction,
      suggestedAddToCart: addToCartAction,
      hasAction: searchAction != null || addToCartAction != null,
      isFailed: isFailed,
      retryQuery: isFailed ? userMessage : null,
    );

    _conversationHistory.add(assistantMsg);
    return assistantMsg;
  }

  /// Tries Groq keys with round-robin failover on 429/401/error and 18s socket resilience
  Future<String?> _tryGroqPool(List<Map<String, String>> messages) async {
    final pool = _groqKeys;
    if (pool.isEmpty) return null;
    final keysToTry = pool.length.clamp(1, 4);
    for (int i = 0; i < keysToTry; i++) {
      final keyIndex = (_groqIndex + i) % pool.length;
      final key = pool[keyIndex];

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 18);
        final request = await client.postUrl(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        ).timeout(const Duration(seconds: 20));
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.headers.set('Authorization', 'Bearer $key');

        final payload = jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 450,
        });

        request.add(utf8.encode(payload));
        final response = await request.close().timeout(const Duration(seconds: 22));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 12));
          final data = jsonDecode(body) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              _groqIndex = (keyIndex + 1) % pool.length;
              return content;
            }
          }
        } else if (response.statusCode == 429 || response.statusCode == 401) {
          debugPrint('Groq Key $keyIndex rate limited (${response.statusCode}), rotating...');
          continue;
        }
      } on SocketException catch (e) {
        debugPrint('Groq Key $keyIndex socket drop: $e');
        break;
      } catch (e) {
        debugPrint('Groq Key $keyIndex exception: $e');
        continue;
      }
    }
    return null;
  }

  /// Tries Gemini 15-key pool (both new AQ format and standard AIzaSy keys)
  /// using gemini-flash-latest with round-robin failover and 18s socket resilience.
  Future<String?> _tryGeminiPool(
    List<Map<String, String>> messages,
    String systemPrompt,
  ) async {
    final contents = <Map<String, dynamic>>[];
    for (final m in messages) {
      final role = m['role'];
      if (role == 'system') continue;
      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': m['content'] ?? ''}
        ],
      });
    }

    if (contents.isEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': 'Hello'}
        ],
      });
    }

    final payload = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.6,
        'maxOutputTokens': 450,
      },
    });

    final keysToTry = _geminiKeys.length.clamp(1, 4);
    final geminiPool = _geminiKeys;
    if (geminiPool.isEmpty) return null;
    for (int i = 0; i < keysToTry; i++) {
      final keyIndex = (_geminiIndex + i) % geminiPool.length;
      final key = geminiPool[keyIndex];

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 18);
        final request = await client.postUrl(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$key',
          ),
        ).timeout(const Duration(seconds: 20));
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.add(utf8.encode(payload));

        final response = await request.close().timeout(const Duration(seconds: 22));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 12));
          final data = jsonDecode(body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final firstCandidate = candidates[0] as Map<String, dynamic>?;
            final contentMap = firstCandidate?['content'] as Map<String, dynamic>?;
            final parts = contentMap?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.trim().isNotEmpty) {
                _geminiIndex = (keyIndex + 1) % geminiPool.length;
                return text;
              }
            }
          }
        } else if (response.statusCode == 429 ||
            response.statusCode == 503 ||
            response.statusCode == 403 ||
            response.statusCode == 400) {
          debugPrint(
            'Gemini Key $keyIndex status (${response.statusCode}), rotating...',
          );
          continue;
        }
      } on SocketException catch (e) {
        debugPrint('Gemini Key $keyIndex socket drop: $e');
        break;
      } catch (e) {
        debugPrint('Gemini Key $keyIndex exception: $e');
        continue;
      }
    }
    return null;
  }

  /// Tries OpenRouter keys with round-robin failover and 18s socket resilience
  Future<String?> _tryOpenRouterPool(List<Map<String, String>> messages) async {
    final pool = _openRouterKeys;
    if (pool.isEmpty) return null;
    final keysToTry = pool.length.clamp(1, 4);
    for (int i = 0; i < keysToTry; i++) {
      final keyIndex = (_openRouterIndex + i) % pool.length;
      final key = pool[keyIndex];

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 18);
        final request = await client.postUrl(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        ).timeout(const Duration(seconds: 20));
        request.headers.set('Content-Type', 'application/json; charset=utf-8');
        request.headers.set('Authorization', 'Bearer $key');
        request.headers.set('HTTP-Referer', 'https://quickopia.app');
        request.headers.set('X-Title', 'Quickopia Supermarket AI');

        final payload = jsonEncode({
          'model': 'meta-llama/llama-3.2-3b-instruct:free',
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 400,
        });

        request.add(utf8.encode(payload));
        final response = await request.close().timeout(const Duration(seconds: 22));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 12));
          final data = jsonDecode(body) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              _openRouterIndex = (keyIndex + 1) % pool.length;
              return content;
            }
          }
        } else if (response.statusCode == 429 || response.statusCode == 401) {
          debugPrint('OpenRouter Key $keyIndex rate limited, rotating...');
          continue;
        }
      } on SocketException catch (e) {
        debugPrint('OpenRouter Key $keyIndex socket drop: $e');
        break;
      } catch (e) {
        debugPrint('OpenRouter Key $keyIndex exception: $e');
        continue;
      }
    }
    return null;
  }

  /// Converts text to speech using ElevenLabs API with 16-key pool rotation.
  /// Returns raw MP3 audio bytes.
  Future<Uint8List?> synthesizeVoiceAudio(String text) async {
    // Strip emojis and action tags before speech
    final cleanText = text
        .replaceAll(RegExp(r'[\u{1f300}-\u{1f5ff}\u{1f900}-\u{1f9ff}\u{1f600}-\u{1f64f}\u{1f680}-\u{1f6ff}\u{2600}-\u{26ff}\u{2700}-\u{27bf}]', unicode: true), '')
        .trim();

    if (cleanText.isEmpty) return null;

    // 1. Try Supabase Edge TTS Function first (keeps ElevenLabs keys secure on backend)
    if (SupabaseConfig.isConfigured) {
      try {
        final res = await SupabaseConfig.client.functions.invoke(
          'ai-tts',
          body: {'text': cleanText},
        ).timeout(const Duration(seconds: 14));

        if (res.status == 200) {
          if (res.data is Uint8List) {
            return res.data as Uint8List;
          } else if (res.data is List<int>) {
            return Uint8List.fromList(res.data as List<int>);
          }
        }
      } catch (e) {
        debugPrint('Supabase Edge TTS attempt failed: $e');
      }
    }

    const voiceId = '21m00Tcm4TlvDq8ikWAM'; // Rachel (clear, friendly multilingual voice)

    final elevenPool = _elevenLabsKeys;
    if (elevenPool.isEmpty) return null;
    for (int i = 0; i < elevenPool.length; i++) {
      final keyIndex = (_elevenLabsIndex + i) % elevenPool.length;
      final key = elevenPool[keyIndex];

      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 12);
        final request = await client.postUrl(
          Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
        );
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('xi-api-key', key);
        request.headers.set('Accept', 'audio/mpeg');

        final payload = jsonEncode({
          'text': cleanText.length > 250 ? cleanText.substring(0, 250) : cleanText,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        });

        request.add(utf8.encode(payload));
        final response = await request.close();

        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (prev, element) => prev..addAll(element));
          _elevenLabsIndex = (keyIndex + 1) % elevenPool.length;
          return Uint8List.fromList(bytes);
        } else if (response.statusCode == 429 || response.statusCode == 401 || response.statusCode == 402) {
          debugPrint('ElevenLabs Key $keyIndex quota/rate limit, rotating...');
          continue;
        }
      } catch (e) {
        debugPrint('ElevenLabs Key $keyIndex exception: $e');
        continue;
      }
    }
    return null;
  }
}
