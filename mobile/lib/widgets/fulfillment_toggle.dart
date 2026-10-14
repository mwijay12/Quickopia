import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FulfillmentToggle extends StatelessWidget {
  final String selected; // 'delivery' | 'pickup'
  final ValueChanged<String> onChanged;

  const FulfillmentToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _tab(context, 'delivery', 'Doorstep Delivery', Icons.delivery_dining),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tab(context, 'pickup', 'Store Pickup', Icons.storefront),
        ),
      ],
    );
  }

  Widget _tab(BuildContext context, String value, String label, IconData icon) {
    final isSelected = selected == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isSelected ? AppTheme.primaryNavy : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black87),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
