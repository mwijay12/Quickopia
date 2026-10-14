import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_constants.dart';
import '../../data/dar_locations_repository.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../services/permission_service.dart';
import '../../utils/currency_formatter.dart';
import 'support_chat_sheet.dart';

class LiveOrderTrackingScreen extends StatefulWidget {
  final Order order;
  final OrderTrackingProvider? trackingProvider;

  const LiveOrderTrackingScreen({
    super.key,
    required this.order,
    this.trackingProvider,
  });

  @override
  State<LiveOrderTrackingScreen> createState() => _LiveOrderTrackingScreenState();
}

class _LiveOrderTrackingScreenState extends State<LiveOrderTrackingScreen> {
  late final MapController _mapController;

  // Default store branch in Mikocheni, Dar es Salaam
  static const LatLng _storeLocation = LatLng(-6.7725, 39.2450);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    PermissionService.requestLocationPermission();
  }

  LatLng _resolveCustomerLocation(Order order) {
    if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
      return LatLng(order.deliveryLatitude!, order.deliveryLongitude!);
    }
    if (order.deliveryNeighborhood != null) {
      final ward = DarLocationsRepository.findWard(order.deliveryNeighborhood!);
      if (ward != null) return ward.center;
    }
    return const LatLng(AppConstants.defaultMapLat, AppConstants.defaultMapLng);
  }

  List<LatLng> _generateRoutePoints(LatLng origin, LatLng destination) {
    // Generate curved, realistic urban route waypoints between store and customer
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLng = (origin.longitude + destination.longitude) / 2;
    final offsetLat = (destination.latitude - origin.latitude) * 0.15;
    final offsetLng = (origin.longitude - destination.longitude) * 0.15;

    final way1 = LatLng(
      origin.latitude * 0.7 + destination.latitude * 0.3 + offsetLat,
      origin.longitude * 0.7 + destination.longitude * 0.3 - offsetLng,
    );
    final way2 = LatLng(midLat - offsetLat, midLng + offsetLng);
    final way3 = LatLng(
      origin.latitude * 0.3 + destination.latitude * 0.7 + offsetLat * 0.5,
      origin.longitude * 0.3 + destination.longitude * 0.7 + offsetLng * 0.5,
    );

    return [origin, way1, way2, way3, destination];
  }

  LatLng _interpolateCourierPosition(List<LatLng> route, String status) {
    if (route.length < 2) return _storeLocation;
    switch (status.toLowerCase()) {
      case 'placed':
        return route[0];
      case 'packing':
        return route[1];
      case 'out_for_delivery':
      case 'in_transit':
      case 'transit':
        return route[3];
      case 'delivered':
      case 'completed':
        return route.last;
      default:
        return route[2];
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer for $phone')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open phone dialer for $phone')),
        );
      }
    }
  }


  bool _isSupabaseReady() {
    try {
      final _ = Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trackingProvider != null) {
      return ChangeNotifierProvider<OrderTrackingProvider>.value(
        value: widget.trackingProvider!,
        child: Consumer<OrderTrackingProvider>(
          builder: (context, tracking, _) =>
              _buildTrackingScaffold(context, tracking.order, tracking),
        ),
      );
    }

    if (_isSupabaseReady()) {
      return ChangeNotifierProvider(
        create: (_) => OrderTrackingProvider(widget.order),
        child: Consumer<OrderTrackingProvider>(
          builder: (context, tracking, _) =>
              _buildTrackingScaffold(context, tracking.order, tracking),
        ),
      );
    }

    return _buildTrackingScaffold(context, widget.order, null);
  }

  Widget _buildTrackingScaffold(
      BuildContext context, Order order, OrderTrackingProvider? tracking) {
    final customerLoc = _resolveCustomerLocation(order);
    final routePoints = _generateRoutePoints(_storeLocation, customerLoc);
    final courierPos = _interpolateCourierPosition(routePoints, order.status);

    return Scaffold(
            body: Stack(
              children: [
                // Map Background (Top View)
                Positioned.fill(
                  bottom: 340, // Leave room for bottom tracking sheet
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: courierPos,
                      initialZoom: 13.8,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.quickopia.app',
                      ),
                      // Route Polyline
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 5.5,
                            color: const Color(0xFF2C3E50),
                          ),
                          Polyline(
                            points: routePoints,
                            strokeWidth: 3.5,
                            color: const Color(0xFFFF5200),
                          ),
                        ],
                      ),
                      // Markers: Store, Destination, Courier
                      MarkerLayer(
                        markers: [
                          // Store Marker
                          Marker(
                            point: _storeLocation,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.storefront, color: Colors.white, size: 22),
                            ),
                          ),

                          // Customer Destination Marker (Glowing Target like in reference)
                          Marker(
                            point: customerLoc,
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF5200).withValues(alpha: 0.3),
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFFFF5200), width: 5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF5200).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Moving Courier Marker (Directional arrow inside circle)
                          Marker(
                            point: courierPos,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Top Floating App Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Color(0xFFFF5200)),
                            SizedBox(width: 6),
                            Text(
                              'Location Tracking',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: tracking != null
                              ? () => tracking.manualRefresh(order.id)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              (tracking?.isReconnecting == true)
                                  ? Icons.sync
                                  : Icons.refresh,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Tracking Card (Dark Modern Card matching mockup)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A), // Sleek dark surface matching reference
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag Pill Handle
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Booking ID & Status Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Id:',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${order.orderNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusBadgeColor(order.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusDisplayLabel(order.status, order.driverId),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Timeline Step Dots
                        _buildStepTimeline(order.status),
                        const SizedBox(height: 16),

                        // Route Details & 3D Box Illustration
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRouteInfo('From', 'Quickopia Mikocheni Store'),
                                  const SizedBox(height: 10),
                                  _buildRouteInfo(
                                    'To',
                                    '${order.deliveryNeighborhood ?? "Customer Location"}${order.deliveryLandmark != null ? ", ${order.deliveryLandmark}" : ""}',
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Customer',
                                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                            ),
                                            Text(
                                              context.read<AuthProvider>().profile?.fullName ?? 'Valued Customer',
                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order Cost',
                                              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                            ),
                                            Text(
                                              CurrencyFormatter.formatTzs(order.totalAmountTzs),
                                              style: const TextStyle(
                                                color: Color(0xFFFF5200),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Stylized 3D Parcel Package Container (matching reference image)
                            Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE2A053), Color(0xFFC77C2B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.shade900.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.inventory_2_rounded,
                                      size: 42,
                                      color: Colors.amber.shade100,
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '${order.items.length} Pcs',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 14),

                        // Driver Contact Bar (Driver Photo, Rating, Call & SMS Buttons)
                        _buildDriverBar(context, order, tracking),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildStepTimeline(String status) {
    final steps = ['Placed', 'Packing', 'Transit', 'Delivered'];
    int activeIndex = 0;
    switch (status.toLowerCase()) {
      case 'placed':
        activeIndex = 0;
        break;
      case 'packing':
      case 'ready':
        activeIndex = 1;
        break;
      case 'out_for_delivery':
      case 'in_transit':
      case 'transit':
        activeIndex = 2;
        break;
      case 'delivered':
      case 'completed':
        activeIndex = 3;
        break;
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIdx = index ~/ 2;
          final isPast = lineIdx < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isPast ? const Color(0xFFFF5200) : Colors.grey.shade700,
            ),
          );
        } else {
          final stepIdx = index ~/ 2;
          final isDone = stepIdx <= activeIndex;
          return Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? const Color(0xFFFF5200) : const Color(0xFF2A2A2A),
              border: Border.all(
                color: isDone ? Colors.white : Colors.grey.shade600,
                width: 1.5,
              ),
            ),
            child: Icon(
              isDone ? Icons.check : Icons.circle,
              size: isDone ? 13 : 6,
              color: Colors.white,
            ),
          );
        }
      }),
    );
  }

  Widget _buildRouteInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDriverBar(BuildContext context, Order order, OrderTrackingProvider? tracking) {
    final hasDriver = order.driverId != null || tracking?.assignedDriver != null;

    if (!hasDriver) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5200).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFFF5200), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assigning Delivery Courier...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connecting with available Quickopia drivers in Dar.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFF333333),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _makePhoneCall(context, '+255711000000'),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.headset_mic_rounded, color: Colors.white70, size: 18),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final driverName = tracking?.assignedDriver?.fullName ?? order.effectiveDriverName;
    final driverPhone = tracking?.assignedDriver?.phone ?? order.effectiveDriverPhone;
    final driverRating = tracking?.assignedDriver?.rating ?? order.effectiveDriverRating;
    final driverVehicle = tracking?.assignedDriver?.vehicleInfo ?? order.effectiveDriverVehicle;
    final avatarUrl = tracking?.assignedDriver?.avatarUrl ?? order.driverAvatarUrl;

    return Row(
      children: [
        // Driver Avatar with Rating Pill
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF2C3E50),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.person, color: Colors.white70, size: 28)
                  : null,
            ),
            Positioned(
              bottom: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.black, size: 10),
                    const SizedBox(width: 1),
                    Text(
                      driverRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Driver Name & Role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driverName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Courier • $driverVehicle',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Action: Call Driver Button (Orange circle matching mockup)
        Material(
          color: const Color(0xFFFF5200),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _makePhoneCall(context, driverPhone),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.call, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Action: Chat / SMS Driver Button (Dark circle matching mockup)
        Material(
          color: const Color(0xFF2C2C2C),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              SupportChatSheet.show(context, initialOrderId: widget.order.id);
            },
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return Colors.blue.shade700;
      case 'packing':
      case 'ready':
        return Colors.amber.shade800;
      case 'out_for_delivery':
      case 'in_transit':
      case 'transit':
        return const Color(0xFF2C3E50);
      case 'delivered':
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusDisplayLabel(String status, [String? driverId]) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Order Placed';
      case 'packing':
        return 'Packing';
      case 'ready':
        return 'Ready for Driver';
      case 'out_for_delivery':
      case 'in_transit':
      case 'transit':
        return driverId != null ? 'In Transit' : 'Assigning Courier';
      case 'delivered':
      case 'completed':
        return 'Delivered';
      default:
        return status.toUpperCase();
    }
  }
}
