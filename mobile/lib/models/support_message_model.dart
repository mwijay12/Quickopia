class SupportMessage {
  final String id;
  final String conversationId;
  final String? senderId;
  final String senderRole; // 'customer', 'admin', 'driver'
  final String senderName;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.content,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String?,
      senderRole: (map['sender_role'] as String?) ?? 'customer',
      senderName: (map['sender_name'] as String?) ?? 'Customer',
      content: (map['content'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      isRead: (map['is_read'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'content': content,
      'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
