class BroadcastNotification {
  final String id;
  final String title;
  final String body;
  final String type; // offer, reminder, alert, system
  final String targetAudience; // all, customers, drivers
  final String? imageUrl;
  final String actionRoute;
  final DateTime createdAt;
  final bool isActive;
  bool isRead;

  BroadcastNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'offer',
    this.targetAudience = 'all',
    this.imageUrl,
    this.actionRoute = '/customer/home',
    required this.createdAt,
    this.isActive = true,
    this.isRead = false,
  });

  factory BroadcastNotification.fromMap(Map<String, dynamic> map) {
    return BroadcastNotification(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'offer',
      targetAudience: (map['target_audience'] as String?) ?? 'all',
      imageUrl: map['image_url'] as String?,
      actionRoute: (map['action_route'] as String?) ?? '/customer/home',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: (map['is_active'] as bool?) ?? true,
      isRead: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'target_audience': targetAudience,
      'image_url': imageUrl,
      'action_route': actionRoute,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
