import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/support_message_model.dart';

class SupportService {
  final _client = SupabaseConfig.client;
  RealtimeChannel? _channel;

  /// Gets an existing open conversation or creates a new one for the customer.
  Future<String> getOrCreateConversation({
    required String customerId,
    String customerName = 'Shopper',
    String? customerPhone,
  }) async {
    try {
      final existing = await _client
          .from('support_conversations')
          .select('id')
          .eq('customer_id', customerId)
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        return existing['id'] as String;
      }

      // Create new conversation
      final created = await _client
          .from('support_conversations')
          .insert({
            'customer_id': customerId,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'status': 'open',
            'last_message': 'Chat started',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return created['id'] as String;
    } catch (e) {
      debugPrint('SupportService: Error getOrCreateConversation: $e');
      rethrow;
    }
  }

  /// Fetches historical messages for a conversation.
  Future<List<SupportMessage>> fetchMessages(String conversationId) async {
    try {
      final response = await _client
          .from('support_messages')
          .select('*')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((m) => SupportMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      debugPrint('SupportService: Error fetchMessages: $e');
      return [];
    }
  }

  /// Sends a message and updates the parent conversation's last message.
  Future<SupportMessage?> sendMessage({
    required String conversationId,
    required String content,
    required String senderRole,
    String senderName = 'Shopper',
    String? senderId,
    String? imageUrl,
  }) async {
    try {
      final res = await _client
          .from('support_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'sender_role': senderRole,
            'sender_name': senderName,
            'content': content.trim(),
            'image_url': imageUrl,
          })
          .select()
          .single();

      // Update conversation
      await _client.from('support_conversations').update({
        'last_message': content.trim(),
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      return SupportMessage.fromMap(Map<String, dynamic>.from(res));
    } catch (e) {
      debugPrint('SupportService: Error sendMessage: $e');
      return null;
    }
  }

  /// Subscribes to real-time incoming messages for the conversation.
  void subscribeToMessages(
    String conversationId,
    void Function(SupportMessage message) onNewMessage,
  ) {
    stopSubscription();
    try {
      _channel = _client
          .channel('public:support_messages:$conversationId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'support_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              if (payload.newRecord.isNotEmpty) {
                final msg = SupportMessage.fromMap(
                  Map<String, dynamic>.from(payload.newRecord),
                );
                onNewMessage(msg);
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('SupportService: Realtime subscription failed: $e');
    }
  }

  /// Cleans up Realtime listener.
  void stopSubscription() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
