import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import '../../models/order_model.dart';
import '../../providers/order_tracking_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/order_receipt_sheet.dart';
import '../../widgets/order_status_timeline.dart';
import 'customer_shell.dart';
import 'live_order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;
  final bool isNewOrder;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    this.isNewOrder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderTrackingProvider(order),
      child: _OrderTrackingView(isNewOrder: isNewOrder),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  final bool isNewOrder;

  const _OrderTrackingView({required this.isNewOrder});

  Future<void> _callDriver(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
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

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<OrderTrackingProvider>();
    final order = tracking.order;
    final isPickup = order.fulfillmentType == 'pickup';

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewOrder ? 'Order Confirmed' : 'Order #${order.orderNumber}'),
        automaticallyImplyLeading: !isNewOrder,
        actions: [
          IconButton(
            icon: tracking.isReconnecting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: tracking.isReconnecting
                ? null
                : () => context
                    .read<OrderTrackingProvider>()
                    .manualRefresh(order.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isNewOrder) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPickup
                        ? 'Show this code at the store counter to collect your order'
                        : 'Your order is confirmed — this screen updates live',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Compact Header in history view
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPickup ? 'Store Pickup' : 'Doorstep Delivery',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          // Pickup Code Card
          if (isPickup) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'PICKUP CODE',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.pickupCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Delivery Snapshot
          if (!isPickup && order.deliveryLandmark != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, color: AppTheme.primaryNavy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.deliveryNeighborhood ?? 'Delivery Area',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          order.deliveryLandmark!,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Order Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          OrderStatusTimeline(
            currentStatus: order.status,
            fulfillmentType: order.fulfillmentType,
          ),

          // Live Map Location Tracking Action (Delivery only)
          if (!isPickup) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFFF5200), width: 1.5),
                ),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveOrderTrackingScreen(order: order),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.near_me_rounded, color: Color(0xFFFF5200), size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Fuatilia Dereva / Live Tracking',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white70),
                ],
              ),
            ),
          ],

          // Assigned Driver Card (Delivery only)
          if (!isPickup && tracking.assignedDriver != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.two_wheeler, color: Colors.green),
                ),
                title: Text(
                  tracking.assignedDriver!.fullName ?? 'Your Driver',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('is assigned and handling your delivery'),
                trailing: tracking.assignedDriver!.phone != null
                    ? IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        tooltip: 'Call Driver',
                        onPressed: () => _callDriver(
                          context,
                          tracking.assignedDriver!.phone!,
                        ),
                      )
                    : null,
              ),
            ),
          ],

          const SizedBox(height: 16),
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.title} x${item.quantity}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatTzs(item.totalTzs),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (order.deliveryFeeTzs > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Fee',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          CurrencyFormatter.formatTzs(order.deliveryFeeTzs),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Paid / Due',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        CurrencyFormatter.formatTzs(order.totalAmountTzs),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // View Official Supermarket Receipt Action
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => OrderReceiptSheet.show(context, order),
            icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryNavy, size: 20),
            label: const Text(
              'View Official Receipt / Risiti Rasmi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryNavy,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Pre-packing customer cancellation action
          if (order.status == 'placed') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmCancelOrder(context, order.id),
              icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
              label: const Text(
                'Cancel Order (Pre-Packing)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],

          if (isNewOrder) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerShell()),
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back to Shopping', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const CustomerShell(initialIndex: 1),
                ),
                (route) => false,
              ),
              child: const Text(
                'View My Orders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(BuildContext context, String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? This action will immediately cancel your order and restore items to store inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await SupabaseConfig.client
          .rpc('cancel_order', params: {'p_order_id': orderId});
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Order cancelled. Items restored to inventory.'),
          backgroundColor: Colors.orange,
        ),
      );
      if (context.mounted) {
        context.read<OrderTrackingProvider>().manualRefresh(orderId);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not cancel order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

