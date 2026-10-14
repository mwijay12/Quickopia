import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_history_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/order_receipt_sheet.dart';
import '../../widgets/order_status_badge.dart';
import 'cart_screen.dart';
import 'live_order_tracking_screen.dart';
import 'order_success_screen.dart';
import '../auth/login_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final VoidCallback? onStartShopping;

  const OrderHistoryScreen({super.key, this.onStartShopping});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      await context.read<OrderHistoryProvider>().load(profile.id);
    }
  }

  Future<void> _handleReorder(BuildContext context, Order order) async {
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Checking live product availability and pricing...'),
        duration: Duration(milliseconds: 900),
      ),
    );

    final res = await cart.reorderFromPastOrder(order.items);
    final int added = res['added'] as int? ?? 0;
    final List<String> skipped = (res['skipped'] as List?)?.cast<String>() ?? [];

    if (!context.mounted) return;

    if (added == 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(skipped.isNotEmpty
              ? 'Items in this order are currently out of stock: ${skipped.join(', ')}'
              : 'Could not reorder items. Please try again.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (skipped.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Added $added item(s) to cart. ${skipped.length} item(s) skipped (${skipped.join(', ')}) due to stock availability.'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Added all $added item(s) to your cart with current live supermarket prices!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<OrderHistoryProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppTheme.brandOrangeGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Orders',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Order History & Live Receipts',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Orders',
            onPressed: _load,
          ),
        ],
      ),
      body: auth.isAuthenticated
          ? RefreshIndicator(
              onRefresh: _load,
              child: _body(history),
            )
          : RefreshIndicator(
              onRefresh: () async {},
              child: _emptyOrdersView(context, isGuest: true),
            ),
    );
  }

  Widget _body(OrderHistoryProvider history) {
    if (history.status == HistoryStatus.loading && history.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (history.orders.isEmpty) {
      return _emptyOrdersView(context);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (history.activeOrders.isNotEmpty) ...[
          _sectionTitle('Active Orders'),
          ...history.activeOrders.map(_orderTile),
          const SizedBox(height: 20),
        ],
        if (history.pastOrders.isNotEmpty) ...[
          _sectionTitle('Past Orders'),
          ...history.pastOrders.map(_orderTile),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryNavy,
          ),
        ),
      );

  Widget _orderTile(Order order) {
    final date = DateFormat('d MMM yyyy, HH:mm').format(order.createdAt.toLocal());
    final itemSummary =
        order.items.map((i) => '${i.title} x${i.quantity}').take(2).join(', ');

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  itemSummary +
                      (order.items.length > 2
                          ? ' +${order.items.length - 2} more'
                          : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · ${order.fulfillmentType == "pickup" ? "Store Pickup" : "Doorstep Delivery"}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: Text(
              CurrencyFormatter.formatTzs(order.totalAmountTzs),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryNavy,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OrderSuccessScreen(order: order, isNewOrder: false),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
            child: Row(
              children: [
                if (order.fulfillmentType == 'delivery' &&
                    order.status != 'delivered' &&
                    order.status != 'cancelled') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFFFF5200)),
                      label: const Text(
                        'Track',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveOrderTrackingScreen(order: order),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined, size: 14, color: AppTheme.primaryNavy),
                    label: const Text(
                      'Receipt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    onPressed: () => OrderReceiptSheet.show(context, order),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppTheme.primaryNavy),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.replay_rounded, size: 14, color: AppTheme.primaryNavy),
                    label: const Text(
                      'Reorder',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    onPressed: () => _handleReorder(context, order),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyOrdersView(BuildContext context, {bool isGuest = false}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Layered glowing container
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentAmber.withValues(alpha: 0.22),
                      AppTheme.primaryNavy.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B2545), Color(0xFF133E68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNavy.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: AppTheme.accentAmber.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 38,
                  color: AppTheme.accentAmber,
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentAmber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fresh status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryOrange.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.primaryOrange),
                SizedBox(width: 6),
                Text(
                  'START YOUR SHOPPING JOURNEY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryOrange,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reassuring title
          const Text(
            'You Have No Orders Yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.neutralDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Friendly, reassuring description
          Text(
            'You haven\'t missed a thing! Our shelves are stocked with fresh daily produce, pantry staples, and beverages. Enjoy 30-minute doorstep delivery across Dar es Salaam or quick in-store pickup without queues.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Value proposition / Service guarantee cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _perkRow(
                  icon: Icons.electric_bolt_rounded,
                  iconColor: Colors.amber.shade700,
                  title: '30-Minute Express Delivery',
                  subtitle: 'Fast and secure doorstep delivery anywhere in Dar es Salaam.',
                ),
                const Divider(height: 16, thickness: 0.7),
                _perkRow(
                  icon: Icons.qr_code_2_rounded,
                  iconColor: Colors.teal.shade700,
                  title: 'Click & Collect (Skip the Queue)',
                  subtitle: 'Order ahead, show your 4-digit PIN at the counter, and collect right away.',
                ),
                const Divider(height: 16, thickness: 0.7),
                _perkRow(
                  icon: Icons.verified_rounded,
                  iconColor: Colors.green.shade700,
                  title: '100% Quality & Price Guarantee',
                  subtitle: 'Real supermarket pricing with inspected, premium quality items.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Primary Call to Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.storefront_rounded, color: Colors.black, size: 20),
              label: const Text(
                'Start Shopping ➔',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 1,
              ),
              onPressed: () {
                if (widget.onStartShopping != null) {
                  widget.onStartShopping!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Refresh Button
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryNavy),
            label: const Text(
              'Refresh Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.primaryNavy,
              ),
            ),
            onPressed: _load,
          ),
          if (isGuest) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              icon: const Icon(Icons.login_rounded, size: 16, color: AppTheme.primaryOrange),
              label: const Text(
                'Already have an account? Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.primaryOrange,
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _perkRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


