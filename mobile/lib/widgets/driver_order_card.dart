import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/navigation_launcher.dart';
import 'order_status_badge.dart';

class DriverOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onMarkComplete;

  const DriverOrderCard({
    super.key,
    required this.order,
    required this.onMarkComplete,
  });

  bool get _isDelivery => order.fulfillmentType == 'delivery';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isDelivery ? 'DOORSTEP DELIVERY' : 'STORE PICKUP HANDOFF',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (_isDelivery) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: AppTheme.primaryNavy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${order.deliveryNeighborhood ?? ""} — ${order.deliveryLandmark ?? ""}',
                      style: const TextStyle(fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppTheme.primaryNavy),
                const SizedBox(width: 6),
                Text(
                  order.customerPhone ?? 'No phone on file',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'To Collect (${order.paymentMethod == "cod" ? "Cash" : "Lipa Namba"}):',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    CurrencyFormatter.formatTzs(order.totalAmountTzs),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionButton(
                  icon: Icons.call,
                  label: 'Call',
                  color: Colors.green.shade700,
                  onTap: order.customerPhone != null
                      ? () => NavigationLauncher.callPhone(order.customerPhone!)
                      : null,
                ),
                _actionButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: Colors.teal.shade700,
                  onTap: order.customerPhone != null
                      ? () => NavigationLauncher.whatsApp(
                            order.customerPhone!,
                            message:
                                'Habari! This is your Quickopia driver for order #${order.orderNumber}.',
                          )
                      : null,
                ),
                if (_isDelivery &&
                    order.deliveryLatitude != null &&
                    order.deliveryLongitude != null)
                  _actionButton(
                    icon: Icons.navigation,
                    label: 'Navigate',
                    color: Colors.blue.shade700,
                    onTap: () => NavigationLauncher.navigateTo(
                      lat: order.deliveryLatitude!,
                      lng: order.deliveryLongitude!,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMarkComplete,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryNavy),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: Text(
                  _isDelivery ? 'Mark as Delivered' : 'Confirm Pickup Handover',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            onTap != null ? color.withValues(alpha: 0.1) : Colors.grey.shade200,
        foregroundColor: onTap != null ? color : Colors.grey.shade500,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
