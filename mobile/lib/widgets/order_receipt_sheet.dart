import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class OrderReceiptSheet extends StatelessWidget {
  final Order order;

  const OrderReceiptSheet({super.key, required this.order});

  static Future<void> show(BuildContext context, Order order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderReceiptSheet(order: order),
    );
  }

  String _generateReceiptText() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());
    final isPickup = order.fulfillmentType == 'pickup';

    final itemsSummary = order.items.map((i) {
      return '• ${i.title} × ${i.quantity} = ${CurrencyFormatter.formatTzs(i.totalTzs)}';
    }).join('\n');

    return '''
*QUICKOPIA EXPRESS SUPERMARKET*
─────────────────────────────
*TAX INVOICE / RISITI YA MAUZO*
Order Ref: #${order.orderNumber}
Date: $formattedDate
Fulfillment: ${isPickup ? 'Store Pickup (Click & Collect)' : 'Express Doorstep Delivery'}
Verification Code: [ ${order.pickupCode} ]
${order.customerPhone != null && order.customerPhone!.isNotEmpty ? 'Customer Phone: ${order.customerPhone}\n' : ''}${order.deliveryLandmark != null && order.deliveryLandmark!.isNotEmpty ? 'Delivery Landmark: ${order.deliveryLandmark}\n' : ''}─────────────────────────────
*ITEMS PURCHASED / BIDHAA:*
$itemsSummary
─────────────────────────────
Subtotal: ${CurrencyFormatter.formatTzs(order.subtotalTzs)}
${order.deliveryFeeTzs > 0 ? 'Delivery Fee: ${CurrencyFormatter.formatTzs(order.deliveryFeeTzs)}\n' : ''}*TOTAL AMOUNT: ${CurrencyFormatter.formatTzs(order.totalAmountTzs)}*
*Payment:* ${order.paymentMethod.toUpperCase()} (${order.paymentStatus.toUpperCase()})
─────────────────────────────
*Asante kwa kufanya manunuzi na Quickopia! Karibu tena.*
_Quickopia Express Retail Platform_
''';
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final text = _generateReceiptText();
    final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    final webUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.primaryNavy,
              content: Text('WhatsApp not available. Receipt copied to clipboard!'),
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primaryNavy,
            content: Text('Receipt copied to clipboard!'),
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    final text = _generateReceiptText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.accentGreen,
        content: Text('Risiti imenakiliwa kikamilifu! (Receipt copied)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy · HH:mm');
    final isPickup = order.fulfillmentType == 'pickup';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Modal Header with Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primaryNavy, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Official Supermarket Receipt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20, color: Colors.grey),
                    tooltip: 'Copy Receipt Text',
                    onPressed: () => _copyToClipboard(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Receipt Body (Paper Style)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Supermarket Brand Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryNavy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.accentAmber,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'QUICKOPIA EXPRESS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Express Retail & On-Demand Delivery',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Dar es Salaam, Tanzania',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'TAX INVOICE / RISITI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      _dottedDivider(),
                      const SizedBox(height: 12),

                      // Order Metadata
                      _receiptRow('Receipt Ref #:', '#${order.orderNumber}', isBoldValue: true),
                      const SizedBox(height: 4),
                      _receiptRow('Date / Tarehe:', dateFormat.format(order.createdAt.toLocal())),
                      const SizedBox(height: 4),
                      _receiptRow('Fulfillment:', isPickup ? 'Store Pickup (Counter)' : 'Doorstep Delivery'),
                      if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _receiptRow('Customer Phone:', order.customerPhone!),
                      ],
                      if (order.deliveryLandmark != null && order.deliveryLandmark!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _receiptRow('Landmark:', order.deliveryLandmark!),
                      ],

                      const SizedBox(height: 12),

                      // Pickup / Delivery Confirmation Code Banner
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryNavy.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPickup ? 'PICKUP CODE:' : 'DELIVERY PIN:',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              order.pickupCode,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      _dottedDivider(),
                      const SizedBox(height: 10),

                      // Itemized Table Header
                      const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              'ITEM / BIDHAA',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'QTY',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TOTAL (TZS)',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Divider(color: Colors.grey.shade300, height: 1),
                      const SizedBox(height: 8),

                      // Items List
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '×${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  CurrencyFormatter.formatTzs(item.totalTzs),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 10),
                      _dottedDivider(),
                      const SizedBox(height: 10),

                      // Pricing Calculation Breakdown
                      _receiptRow('Subtotal:', CurrencyFormatter.formatTzs(order.subtotalTzs)),
                      const SizedBox(height: 4),
                      _receiptRow(
                        'Delivery Fee:',
                        order.deliveryFeeTzs > 0
                            ? CurrencyFormatter.formatTzs(order.deliveryFeeTzs)
                            : 'FREE (0 TZS)',
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade400, thickness: 1),
                      const SizedBox(height: 6),

                      // Grand Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL AMOUNT:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatTzs(order.totalAmountTzs),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Payment Status & Method Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payment, size: 16, color: AppTheme.primaryNavy),
                                const SizedBox(width: 6),
                                Text(
                                  'Method: ${order.paymentMethod.toUpperCase()}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: order.paymentStatus.toLowerCase() == 'paid'
                                    ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.paymentStatus.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: order.paymentStatus.toLowerCase() == 'paid'
                                      ? AppTheme.accentGreen
                                      : Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Asante kwa kuchagua Quickopia!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Karibu tena · Fresh Groceries at your fingertips',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions (WhatsApp Share & Done)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Text'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _copyToClipboard(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Share WhatsApp Receipt',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => _shareWhatsApp(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
            color: AppTheme.primaryNavy,
          ),
        ),
      ],
    );
  }

  Widget _dottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }
}
