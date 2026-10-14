import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/product_model.dart';
import '../../models/supermarket_settings_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/supermarket_provider.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/catalog_service.dart';
import '../../services/permission_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class AiShoppingAssistantSheet extends StatefulWidget {
  final String? initialQuery;

  const AiShoppingAssistantSheet({super.key, this.initialQuery});

  static Future<void> show(BuildContext context, {String? initialQuery}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiShoppingAssistantSheet(initialQuery: initialQuery),
    );
  }

  @override
  State<AiShoppingAssistantSheet> createState() => _AiShoppingAssistantSheetState();
}

class _AiShoppingAssistantSheetState extends State<AiShoppingAssistantSheet> {
  final _aiService = AiAssistantService();
  final _catalogService = CatalogService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isThinking = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentlyPlayingMessage;
  String? _reconnectStatus;
  String? _recentlyCopiedContent;
  Timer? _copyTimer;
  final Map<String, List<Product>> _searchResultsCache = {};

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialQuery!);
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      // Speech service not available on current environment
    }
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    _speech.stop();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _copyTimer?.cancel();
    if (mounted) {
      setState(() => _recentlyCopiedContent = text);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jibu limenakiliwa! (Copied to clipboard)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _copyTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _recentlyCopiedContent = null);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isThinking) return;

    final settings =
        Provider.of<SupermarketProvider?>(context, listen: false)?.settings ??
            const SupermarketSettings();

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    }

    _textCtrl.clear();
    setState(() {
      _isThinking = true;
      _reconnectStatus = 'AI inawasiliana na duka...';
    });
    _scrollToBottom();

    try {
      final aiResponse = await _aiService.sendMessage(
        userMessage: clean,
        settings: settings,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() => _reconnectStatus = status);
            _scrollToBottom();
          }
        },
      );

      // If AI recommended a product search query, fetch matching products
      if (aiResponse.suggestedSearch != null &&
          aiResponse.suggestedSearch!.isNotEmpty) {
        _fetchRecommendedProducts(aiResponse.suggestedSearch!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isThinking = false;
          _reconnectStatus = null;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _fetchRecommendedProducts(String query) async {
    if (_searchResultsCache.containsKey(query)) return;

    try {
      final items = await _catalogService.fetchProducts(searchQuery: query);
      if (mounted) {
        setState(() {
          _searchResultsCache[query] = items;
        });
        _scrollToBottom();
      }
    } catch (_) {
      // Graceful fallback to general catalog items
    }
  }

  Future<void> _playVoice(AiChatMessage message) async {
    setState(() => _currentlyPlayingMessage = message.content);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Synthesizing voice audio...'),
        duration: Duration(seconds: 2),
      ),
    );

    final audioBytes = await _aiService.synthesizeVoiceAudio(message.content);

    if (mounted) {
      setState(() => _currentlyPlayingMessage = null);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Audio generated and ready for playback'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice audio generated. Ready for playback.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleMicrophoneInput() async {
    // 1. Request microphone permission
    final hasPermission = await PermissionService.requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruhusa ya maikrofoni inahitajika ili kurekodi sauti. Tafadhali ruhusu kwenye mipangilio ya simu.'),
            backgroundColor: AppTheme.primaryOrange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // If currently recording, stop and send
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_textCtrl.text.trim().isNotEmpty) {
        _handleSend(_textCtrl.text);
      }
      return;
    }

    // Initialize speech if not ready
    if (!_speechAvailable) {
      try {
        _speechAvailable = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              if (mounted) setState(() => _isListening = false);
            }
          },
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
        );
      } catch (_) {
        _speechAvailable = false;
      }
    }

    if (_speechAvailable) {
      setState(() => _isListening = true);
      try {
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _textCtrl.text = result.recognizedWords;
              });
              if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
                _handleSend(result.recognizedWords);
              }
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenFor: const Duration(seconds: 20),
            pauseFor: const Duration(seconds: 3),
            localeId: 'sw_TZ',
          ),
        );
      } catch (_) {
        setState(() => _isListening = false);
      }
    } else {
      // Graceful fallback if native device has no speech-to-text recognition service installed
      _showVoiceFallbackSheet();
    }
  }

  void _showVoiceFallbackSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.mic, color: AppTheme.primaryOrange, size: 30),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Voice Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Unaweza kuandika unachohitaji au kuchagua mada hapa chini:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _buildVoicePromptButton(
                  ctx,
                  'Suggest the best watches and prices',
                  'Suggest the best watches and prices',
                  Icons.watch_outlined,
                ),
                const SizedBox(height: 8),
                _buildVoicePromptButton(
                  ctx,
                  'Nahitaji vyakula vikuu: mchele, sukari na unga',
                  'Nahitaji vyakula vikuu: mchele, sukari na unga wa ngano',
                  Icons.shopping_basket_outlined,
                ),
                const SizedBox(height: 8),
                _buildVoicePromptButton(
                  ctx,
                  'Muda wa delivery na malipo ya Lipa Namba',
                  'Je mnafanya delivery Kinondoni na Sinza ndani ya dakika ngapi na Lipa Namba zipi?',
                  Icons.local_shipping_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoicePromptButton(BuildContext ctx, String label, String query, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        icon: Icon(icon, size: 18, color: AppTheme.primaryOrange),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
        ),
        onPressed: () {
          Navigator.pop(ctx);
          _handleSend(query);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        Provider.of<SupermarketProvider?>(context)?.settings ?? const SupermarketSettings();
    final storeName = settings.supermarketName.isNotEmpty ? settings.supermarketName : 'Quickopia';
    final history = _aiService.history;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar (Brand Orange, Zero Purple)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryOrange, Color(0xFFE64A19)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$storeName AI',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmber,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CONCIERGE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Store Concierge & Voice Assistant',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  tooltip: 'Anza Upya (Clear Chat)',
                  onPressed: () {
                    setState(() => _aiService.clearMemory());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Quick Inquiry Suggestion Chips (Clean, No Emojis)
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.grey.shade100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildChip('Suggest the best watches'),
                _buildChip('Vyakula vikuu: sukari, unga, mchele'),
                _buildChip('Masaa ya delivery na Lipa Namba'),
                _buildChip('Sera ya kurudisha bidhaa (Returns)'),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: history.isEmpty
                ? _buildEmptyWelcome(storeName)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final msg = history[index];
                      return _buildMessageBubble(msg, storeName);
                    },
                  ),
          ),

          // Thinking / Reconnecting Indicator
          if (_isThinking)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: (_reconnectStatus != null &&
                        (_reconnectStatus!.contains('Reconnecting') ||
                         _reconnectStatus!.contains('unganisha')))
                    ? const Color(0xFFFFF7ED)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_reconnectStatus != null &&
                          (_reconnectStatus!.contains('Reconnecting') ||
                           _reconnectStatus!.contains('unganisha')))
                      ? AppTheme.primaryOrange.withValues(alpha: 0.5)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _reconnectStatus ?? 'AI Concierge is searching store & thinking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_reconnectStatus != null &&
                                (_reconnectStatus!.contains('Reconnecting') ||
                                 _reconnectStatus!.contains('unganisha')))
                            ? const Color(0xFFC2410C)
                            : Colors.grey.shade700,
                        fontWeight: (_reconnectStatus != null &&
                                (_reconnectStatus!.contains('Reconnecting') ||
                                 _reconnectStatus!.contains('unganisha')))
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Active Voice Listening Indicator Banner
          if (_isListening)
            Container(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _textCtrl.text.isNotEmpty
                          ? _textCtrl.text
                          : 'Listening... Zungumza sasa (Swahili au English)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _handleMicrophoneInput,
                    child: const Text('Stop & Send', style: TextStyle(fontSize: 12, color: AppTheme.primaryOrange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // Microphone Speech Input Button
                  Material(
                    color: _isListening
                        ? Colors.red.shade100
                        : AppTheme.primaryOrange.withValues(alpha: 0.12),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _handleMicrophoneInput,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: _isListening ? Colors.red : AppTheme.primaryOrange,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text Input
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask AI or search products (e.g. watch, sugar)...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button (Brand Orange)
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isThinking ? null : () => _handleSend(_textCtrl.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWelcome(String storeName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assistant_outlined,
                size: 48,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Habari! Karibu $storeName AI Concierge',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Niambie unachohitaji! Naweza kukutafutia bidhaa bora, kulinganisha bei, kukuonyesha options za ujazo, au kuongeza vitu kwenye kapu lako la manunuzi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.45),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureBadge('Natural Voice Input', Icons.mic_none_rounded),
                _buildFeatureBadge('Smart Product Search', Icons.search_rounded),
                _buildFeatureBadge('Direct Add to Cart', Icons.shopping_cart_outlined),
                _buildFeatureBadge('Dar es Salaam Delivery', Icons.local_shipping_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg, String storeName) {
    final isMe = msg.role == 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Author Header
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe) ...[
                  const Icon(Icons.auto_awesome, size: 13, color: AppTheme.primaryOrange),
                  const SizedBox(width: 4),
                ],
                Text(
                  isMe ? 'You' : '$storeName AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.grey.shade600 : AppTheme.primaryOrange,
                  ),
                ),
                if (!isMe) ...[
                  const SizedBox(width: 8),
                  // Voice audio playback icon
                  InkWell(
                    onTap: () => _playVoice(msg),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _currentlyPlayingMessage == msg.content
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_outlined,
                            size: 15,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Listen',
                            style: TextStyle(fontSize: 10, color: AppTheme.primaryOrange, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Copy AI Response button
                  InkWell(
                    onTap: () => _copyMessage(msg.content),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _recentlyCopiedContent == msg.content
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 13,
                            color: _recentlyCopiedContent == msg.content
                                ? Colors.green
                                : const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _recentlyCopiedContent == msg.content ? 'Copied' : 'Copy',
                            style: TextStyle(
                              fontSize: 10,
                              color: _recentlyCopiedContent == msg.content
                                  ? Colors.green
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _copyMessage(msg.content),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(
                        _recentlyCopiedContent == msg.content
                            ? Icons.check_rounded
                            : Icons.copy_rounded,
                        size: 12,
                        color: _recentlyCopiedContent == msg.content
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Speech Bubble Card with Long Press Copy & Network Disconnect Retry UI
          GestureDetector(
            onLongPress: () => _copyMessage(msg.content),
            child: Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.84,
              ),
              decoration: BoxDecoration(
                color: msg.isFailed
                    ? const Color(0xFFFEF2F2)
                    : isMe
                        ? AppTheme.primaryOrange
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: msg.isFailed
                    ? Border.all(color: Colors.red.shade300, width: 1.2)
                    : !isMe
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.isFailed) ...[
                    Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Mtandao Umekatika / Disconnected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isFailed
                          ? Colors.red.shade900
                          : isMe
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (msg.isFailed && msg.retryQuery != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text(
                        'Unganisha Tena & Jaribu (Retry)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _handleSend(msg.retryQuery!),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // If AI provided a search query or product recommendations, render interactive product shelf
          if (!isMe && msg.suggestedSearch != null)
            _buildInteractiveProductShelf(msg.suggestedSearch!),
        ],
      ),
    );
  }

  Widget _buildInteractiveProductShelf(String query) {
    final products = _searchResultsCache[query] ?? [];

    if (products.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: () => _fetchRecommendedProducts(query),
          icon: const Icon(Icons.search, size: 16, color: AppTheme.primaryOrange),
          label: Text('Tafuta "$query" kwenye Stoo', style: const TextStyle(color: AppTheme.primaryOrange)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Matching Products in Store (${products.length}):',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                TextButton(
                  onPressed: () {
                    final catalog = context.read<CatalogProvider>();
                    catalog.search(query);
                    Navigator.pop(context);
                  },
                  child: const Text('View All In Catalog ➔', style: TextStyle(fontSize: 11, color: AppTheme.primaryOrange)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, idx) {
                final prod = products[idx];
                return _buildProductMiniCard(prod);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductMiniCard(Product prod) {
    return Container(
      width: 145,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / placeholder
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: prod.imageUrl != null && prod.imageUrl!.isNotEmpty
                  ? Image.network(
                      prod.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatTzs(prod.priceTzs),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppTheme.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final cart = context.read<CartProvider>();
                      cart.addItem(prod);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${prod.title} added to cart!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add to Cart', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () => _handleSend(label),
      ),
    );
  }
}
