import 'package:flutter/material.dart';
import '../models/branch_model.dart';
import '../theme/app_theme.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selected; // 'cod' | 'lipa_namba'
  final ValueChanged<String> onChanged;
  final Branch? branch;
  final TextEditingController referenceController;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.branch,
    required this.referenceController,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup<String>(
      groupValue: selected,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RadioListTile<String>(
            value: 'cod',
            activeColor: AppTheme.primaryNavy,
            title: Text('Cash on Delivery / Store Pickup', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Pay with cash when your items arrive or upon store collection'),
          ),
          const RadioListTile<String>(
            value: 'lipa_namba',
            activeColor: AppTheme.primaryNavy,
            title: Text('Lipa Kwa Simu (M-Pesa / Tigo Pesa / Airtel Money)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Send payment directly to our merchant till / Lipa Namba'),
          ),
          if (selected == 'lipa_namba')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lipa Namba: ${branch?.phone ?? "+255 700 000 000"}\n'
                            'Name: ${branch?.name ?? "Quickopia Supermarket"}\n'
                            'Enter this number in your mobile money menu, then optionally enter your transaction reference below.',
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: referenceController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Money Transaction Reference (optional)',
                      hintText: 'e.g. 9KA47B89XX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
