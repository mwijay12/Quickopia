import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/broadcast_notification_model.dart';
import '../theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  RealtimeChannel? _broadcastChannel;

  final ValueNotifier<List<BroadcastNotification>> broadcastsNotifier =
      ValueNotifier<List<BroadcastNotification>>([]);

  static const String _channelId = 'quickopia_orders';
  static const String _channelName = 'Quickopia Order Updates';
  static const String _channelDesc =
      'High-priority order status, delivery, and shopping notifications';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle tap on native notification if needed
        },
      );

      // Create high-importance Android channel with public visibility for Lock Screens
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );

        // Request POST_NOTIFICATIONS permission on Android 13+
        await androidImplementation.requestNotificationsPermission();
      }

      startBroadcastListener();
      _isInitialized = true;
    } catch (e) {
      // In tests or environments without native platform channels, gracefully fallback
      _isInitialized = true;
    }
  }

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  Future<void> loadActiveBroadcasts() async {
    if (_isTesting || !SupabaseConfig.isConfigured) return;
    try {
      final res = await SupabaseConfig.client
          .from('broadcast_notifications')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((m) => BroadcastNotification.fromMap(Map<String, dynamic>.from(m)))
          .toList();
      broadcastsNotifier.value = list;
    } catch (e) {
      debugPrint('NotificationService: Failed to fetch broadcasts: $e');
    }
  }

  void startBroadcastListener() {
    if (_isTesting || !SupabaseConfig.isConfigured) return;
    loadActiveBroadcasts();

    try {
      _broadcastChannel = SupabaseConfig.client
          .channel('public:broadcast_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'broadcast_notifications',
            callback: (payload) {
              if (payload.eventType == PostgresChangeEvent.insert &&
                  payload.newRecord.isNotEmpty) {
                final notif = BroadcastNotification.fromMap(
                  Map<String, dynamic>.from(payload.newRecord),
                );
                broadcastsNotifier.value = [notif, ...broadcastsNotifier.value];

                // Trigger in-app top drop-down banner ("ziwe juu") and native lock screen
                showOrderNotification(
                  title: notif.title,
                  body: notif.body,
                );
              } else if (payload.eventType == PostgresChangeEvent.delete) {
                final deletedId = payload.oldRecord['id'] as String?;
                if (deletedId != null) {
                  broadcastsNotifier.value = broadcastsNotifier.value
                      .where((n) => n.id != deletedId)
                      .toList();
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('NotificationService: Broadcast listener failed: $e');
    }
  }

  void stopBroadcastListener() {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
  }

  /// Broadcasts notification both natively (visible on Lock Screen) and In-App (top banner)
  Future<void> showOrderNotification({
    required String title,
    required String body,
    String? payload,
    BuildContext? context,
    VoidCallback? onTap,
  }) async {
    // 1. Trigger In-App Top Notification Banner ("ziwe juu") immediately
    showTopInAppBanner(
      title: title,
      body: body,
      context: context,
      onTap: onTap,
    );

    // 2. Trigger Native Notification (Configured for Lock Screen Visibility)
    await _showNativeNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> _showNativeNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        // CRITICAL FOR LOCK SCREEN: NotificationVisibility.public ensures notifications are visible natively on locked devices
        visibility: NotificationVisibility.public,
        ticker: 'Quickopia Notification',
        category: AndroidNotificationCategory.status,
        icon: '@mipmap/ic_launcher',
        color: AppTheme.primaryOrange,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (_) {
      // Silently catch native issues in headless/test environments
    }
  }

  /// Displays a floating heads-up banner at the very top of the screen ("ziwe juu")
  void showTopInAppBanner({
    required String title,
    required String body,
    BuildContext? context,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final effectiveContext = context ?? navigatorKey.currentContext;
    if (effectiveContext == null) return;

    final overlay = Overlay.maybeOf(effectiveContext);
    if (overlay == null) return;

    // Haptic feedback for tactile feel
    HapticFeedback.lightImpact();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => _TopInAppNotificationBanner(
        title: title,
        body: body,
        onTap: () {
          overlayEntry.remove();
          if (onTap != null) onTap();
        },
        onDismiss: () {
          overlayEntry.remove();
        },
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopInAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopInAppNotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopInAppNotificationBanner> createState() =>
      _TopInAppNotificationBannerState();
}

class _TopInAppNotificationBannerState
    extends State<_TopInAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Icon / Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryOrange,
                            AppTheme.primaryOrangeLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NOW',
                                  style: TextStyle(
                                    color: AppTheme.primaryOrangeLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.body,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss Button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
