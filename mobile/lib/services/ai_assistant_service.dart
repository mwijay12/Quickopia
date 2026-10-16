import 'dart:async';
import 'package:flutter/foundation.dart';
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

/// Secure AI Concierge client.
///
/// SECURITY: All LLM / TTS provider keys (Groq, Gemini, OpenRouter,
/// ElevenLabs) live ONLY in Supabase Secrets (server-side) and are used
/// ONLY inside Edge Functions (`ai-assistant`, `ai-tts`).
/// This file makes ZERO direct calls to api.groq.com, generativelanguage,
/// openrouter.ai or api.elevenlabs.io, and reads ZERO provider keys from
/// `.env`. That keeps the compiled APK clean — unzipping the APK reveals
/// only images/icons, no secrets.
///
/// Free-tier friendly: set pools in Supabase Dashboard / CLI:
///   supabase secrets set GROQ_KEYS="gsk_...,gsk_..."
///   supabase secrets set GEMINI_KEYS="..."
///   supabase secrets set OPENROUTER_KEYS="..."
///   supabase secrets set ELEVENLABS_KEYS="..."
class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();
  factory AiAssistantService() => _instance;
  AiAssistantService._internal();

  // Multi-Turn Session Memory
  final List<AiChatMessage> _conversationHistory = [];
  List<AiChatMessage> get history => List.unmodifiable(_conversationHistory);

  void clearMemory() {
    _conversationHistory.clear();
  }

  /// Sends a message via the `ai-assistant` Edge Function only.
  /// Resilient to shaky cellular networks with 3 attempts + backoff.
  Future<AiChatMessage> sendMessage({
    required String userMessage,
    required SupermarketSettings settings,
    void Function(String status)? onStatusUpdate,
  }) async {
    final userChat = AiChatMessage(role: 'user', content: userMessage.trim());
    _conversationHistory.add(userChat);

    final recent = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;

    String? responseText;
    const int maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt == 1) {
        onStatusUpdate?.call('AI Concierge is connecting...');
      } else {
        onStatusUpdate?.call(
            'Reconnecting to AI network (Attempt $attempt/$maxAttempts)... Inajaribu kuunganisha tena...');
        await Future.delayed(Duration(milliseconds: 1200 * (attempt - 1)));
      }

      try {
        if (!SupabaseConfig.isConfigured) {
          debugPrint('AI: Supabase not configured, skipping Edge call.');
          break;
        }

        final res = await SupabaseConfig.client.functions
            .invoke(
              'ai-assistant',
              body: {
                'message': userMessage,
                'history': recent
                    .map((m) => {'role': m.role, 'content': m.content})
                    .toList(),
                'settings': {
                  'supermarketName': settings.supermarketName,
                  'branchAddress': settings.branchAddress,
                  'operatingHours': settings.operatingHours,
                  'phone': settings.phone,
                  'email': settings.email,
                  'returnWindowHours': settings.returnWindowHours,
                },
              },
            )
            .timeout(const Duration(seconds: 22));

        if (res.status == 200 && res.data is Map) {
          final reply = (res.data as Map)['reply'] as String?;
          if (reply != null && reply.trim().isNotEmpty) {
            responseText = reply;
            break;
          }
        } else {
          debugPrint('AI Edge status ${res.status}: ${res.data}');
        }
      } catch (e) {
        debugPrint('AI Edge attempt $attempt failed: $e');
      }
    }

    final bool isFailed = responseText == null || responseText.trim().isEmpty;

    final String text = isFailed
        ? 'Samahani, mtandao ulikatika wakati wa kuunganisha na AI Concierge. Tafadhali hakikisha simu imeunganishwa kwenye intaneti kisha bonyeza "Jaribu Tena" (Tap to Reconnect & Retry).'
        : responseText;

    // Parse action tags from AI output
    String? searchAction;
    String? addToCartAction;

    final searchMatch = RegExp(r'\[SEARCH:\s*([^\]]+)\]', caseSensitive: false)
        .firstMatch(text);
    if (searchMatch != null && searchMatch.groupCount >= 1) {
      searchAction = searchMatch.group(1)?.trim();
    }

    final addMatch =
        RegExp(r'\[ADD_TO_CART:\s*([^\]]+)\]', caseSensitive: false)
            .firstMatch(text);
    if (addMatch != null && addMatch.groupCount >= 1) {
      addToCartAction = addMatch.group(1)?.trim();
    }

    // Clean tags and raw markdown headers/asterisks from displayed content
    final cleanContent = text
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

  /// Converts text to speech via the `ai-tts` Edge Function only.
  /// Returns raw MP3 audio bytes. No ElevenLabs key on device.
  Future<Uint8List?> synthesizeVoiceAudio(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    if (!SupabaseConfig.isConfigured) return null;

    try {
      final res = await SupabaseConfig.client.functions
          .invoke(
            'ai-tts',
            body: {'text': cleanText},
          )
          .timeout(const Duration(seconds: 14));

      if (res.status == 200) {
        if (res.data is Uint8List) {
          return res.data as Uint8List;
        } else if (res.data is List<int>) {
          return Uint8List.fromList(res.data as List<int>);
        } else {
          debugPrint('TTS Edge returned unexpected type: ${res.data.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('Supabase Edge TTS attempt failed: $e');
    }
    return null;
  }
}
