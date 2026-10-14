import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus; // 'placed' | 'packing' | 'ready' | 'out_for_delivery' | 'delivered' | 'cancelled'
  final String fulfillmentType; // 'delivery' | 'pickup'

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
    required this.fulfillmentType,
  });

  List<Map<String, String>> get _steps {
    if (fulfillmentType == 'pickup') {
      return [
        {'key': 'placed', 'label': 'Order Placed'},
        {'key': 'packing', 'label': 'Packing'},
        {'key': 'ready', 'label': 'Ready for Pickup'},
        {'key': 'delivered', 'label': 'Collected'},
      ];
    }
    return [
      {'key': 'placed', 'label': 'Order Placed'},
      {'key': 'packing', 'label': 'Packing'},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery'},
      {'key': 'delivered', 'label': 'Delivered'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final currentIndex = steps.indexWhere((s) => s['key'] == currentStatus);

    if (currentStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'This order was cancelled.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = currentIndex != -1 && i <= currentIndex;
        final isLast = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone ? Colors.green : Colors.grey.shade400,
                    size: 22,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone && i < currentIndex
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  steps[i]['label']!,
                  style: TextStyle(
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? Colors.black87 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
