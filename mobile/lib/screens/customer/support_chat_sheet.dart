import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supermarket_settings_model.dart';
import '../../models/support_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supermarket_provider.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';

class SupportChatSheet extends StatefulWidget {
  final String? initialOrderId;

  const SupportChatSheet({super.key, this.initialOrderId});

  static Future<void> show(BuildContext context, {String? initialOrderId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupportChatSheet(initialOrderId: initialOrderId),
    );
  }

  @override
  State<SupportChatSheet> createState() => _SupportChatSheetState();
}

class _SupportChatSheetState extends State<SupportChatSheet> {
  final _supportService = SupportService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<SupportMessage> _messages = [];
  String? _conversationId;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final auth = context.read<AuthProvider>();
    final customerId = auth.profile?.id ?? 'guest_shopper';
    final customerName = auth.profile?.fullName ?? 'Shopper';
    final customerPhone = auth.profile?.phone;

    try {
      final convId = await _supportService.getOrCreateConversation(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      final msgs = await _supportService.fetchMessages(convId);

      if (mounted) {
        setState(() {
          _conversationId = convId;
          _messages = msgs;
          _loading = false;
        });

        _scrollToBottom();

        // Subscribe to real-time incoming messages
        _supportService.subscribeToMessages(convId, (newMsg) {
          if (mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == newMsg.id)) {
                _messages.add(newMsg);
              }
            });
            _scrollToBottom();
          }
        });

        // If an initial order inquiry was passed, post a prompt if empty
        if (widget.initialOrderId != null && msgs.isEmpty) {
          _sendMessage('Habari! Nina swali kuhusu agizo langu #${widget.initialOrderId!.substring(0, 8)}.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _supportService.stopSubscription();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _conversationId == null || _sending) return;

    final auth = context.read<AuthProvider>();
    _textCtrl.clear();
    setState(() => _sending = true);

    try {
      final sent = await _supportService.sendMessage(
        conversationId: _conversationId!,
        content: clean,
        senderRole: 'customer',
        senderName: auth.profile?.fullName ?? 'Shopper',
        senderId: auth.profile?.id,
      );

      if (mounted && sent != null) {
        setState(() {
          if (!_messages.any((m) => m.id == sent.id)) {
            _messages.add(sent);
          }
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        Provider.of<SupermarketProvider?>(context)?.settings ?? const SupermarketSettings();
    final storeName = settings.supermarketName.isNotEmpty ? settings.supermarketName : 'Quickopia';

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.support_agent_rounded, color: AppTheme.accentAmber, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$storeName Help Desk',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Staff Online • Live Messenger',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Quick Inquiry Chips
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.grey.shade100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip('📦 Where is my order?'),
                _buildQuickChip('🍎 Damaged or missing item'),
                _buildQuickChip('🛵 Speak with delivery rider'),
                _buildQuickChip('🛍️ Inquire product stock'),
              ],
            ),
          ),

          // Message Thread
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryNavy.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Habari! Karibu $storeName Support.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tuma ujumbe hapa kuhusu oda yako au bidhaa zozote, wafanyakazi wetu watakujibu mara moja.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderRole == 'customer';
                          final isDriver = msg.senderRole == 'driver';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
                                    child: Text(
                                      isMe
                                          ? 'You'
                                          : isDriver
                                              ? '🛵 Rider (${msg.senderName})'
                                              : '🏬 $storeName Support',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppTheme.primaryNavy
                                          : isDriver
                                              ? const Color(0xFF059669)
                                              : Colors.grey.shade100,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMe
                                            ? const Radius.circular(16)
                                            : const Radius.circular(2),
                                        bottomRight: isMe
                                            ? const Radius.circular(2)
                                            : const Radius.circular(16),
                                      ),
                                      border: !isMe && !isDriver
                                          ? Border.all(color: Colors.grey.shade300)
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: isMe || isDriver ? Colors.white : Colors.black87,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                                    child: Text(
                                      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Andika ujumbe wako hapa...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sending ? null : () => _sendMessage(_textCtrl.text),
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
