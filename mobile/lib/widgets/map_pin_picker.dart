import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/app_constants.dart';

class MapPinPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final ValueChanged<LatLng> onPositionSelected;
  final MapController? mapController;

  const MapPinPicker({
    super.key,
    this.initialPosition,
    required this.onPositionSelected,
    this.mapController,
  });

  @override
  State<MapPinPicker> createState() => _MapPinPickerState();
}

class _MapPinPickerState extends State<MapPinPicker> {
  late LatLng _position;
  late final MapController _internalController;
  MapController get _effectiveController => widget.mapController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = MapController();
    _position = widget.initialPosition ??
        const LatLng(AppConstants.defaultMapLat, AppConstants.defaultMapLng);
  }

  @override
  void didUpdateWidget(covariant MapPinPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != null && widget.initialPosition != oldWidget.initialPosition) {
      setState(() => _position = widget.initialPosition!);
      try {
        _effectiveController.move(widget.initialPosition!, 15.5);
      } catch (_) {}
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() => _position = point);
    widget.onPositionSelected(point);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _effectiveController,
              options: MapOptions(
                initialCenter: _position,
                initialZoom: 14,
                onTap: _onTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.quickopia.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Mandatory OpenStreetMap attribution
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
