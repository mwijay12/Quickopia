import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/driver_orders_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';

class DriverReportsView extends StatelessWidget {
  const DriverReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final driverOrders = context.watch<DriverOrdersProvider>();

    return RefreshIndicator(
      onRefresh: () => driverOrders.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header title
          const Text(
            'Ripoti ya Mapato & Uwasilishaji',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Muhtasari wa safari ulizokamilisha na malipo yako ya delivery.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // Primary Stats Cards Grid
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Leo (Today)',
                  metric: '${driverOrders.todayCompletedCount} safari',
                  subMetric: CurrencyFormatter.formatTzs(driverOrders.todayEarningsTzs),
                  icon: Icons.today,
                  iconColor: AppTheme.primaryNavy,
                  bgColor: AppTheme.primaryNavy.withValues(alpha: 0.05),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Jumla ya Safari',
                  metric: '${driverOrders.totalCompletedCount} safari',
                  subMetric: CurrencyFormatter.formatTzs(driverOrders.totalEarningsTzs),
                  icon: Icons.all_inclusive,
                  iconColor: AppTheme.accentGreen,
                  bgColor: AppTheme.accentGreen.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payout Status Card
          Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryNavy, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hali ya Malipo (Payout Status)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PayoutStatusColumn(
                        title: 'Yaliyolipwa (Settled)',
                        amount: driverOrders.settledPayoutTzs,
                        badgeColor: Colors.green,
                        badgeText: 'PAID',
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade200),
                      _PayoutStatusColumn(
                        title: 'Inasubiri (Pending)',
                        amount: driverOrders.pendingPayoutTzs,
                        badgeColor: Colors.orange,
                        badgeText: 'PENDING',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Completed Deliveries Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Historia ya Safari (History)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              Text(
                '${driverOrders.completedOrders.length} zilizokamilika',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (driverOrders.completedOrders.isEmpty)
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 40, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Bado haujakamilisha safari yoyote',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ukikamilisha oda ya kwanza, itaonekana hapa ikiwa na maelezo ya malipo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...driverOrders.completedOrders.map((order) => _CompletedOrderTile(order: order)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String metric;
  final String subMetric;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.metric,
    required this.subMetric,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metric,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subMetric,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutStatusColumn extends StatelessWidget {
  final String title;
  final double amount;
  final Color badgeColor;
  final String badgeText;

  const _PayoutStatusColumn({
    required this.title,
    required this.amount,
    required this.badgeColor,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatTzs(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: badgeColor == Colors.green ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
      ],
    );
  }
}

class _CompletedOrderTile extends StatelessWidget {
  final Order order;

  const _CompletedOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final isPaid = order.paymentStatus == 'paid';

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                    fontSize: 14,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPaid ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.schedule,
                        size: 12,
                        color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'Paid' : 'Pending Settlement',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${order.deliveryNeighborhood ?? ""} ${order.deliveryLandmark != null ? "• ${order.deliveryLandmark!}" : ""}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(order.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  '+${CurrencyFormatter.formatTzs(order.deliveryFeeTzs)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
