import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/driver_order_service.dart';
import '../theme/app_theme.dart';

class MarkDeliveredSheet extends StatefulWidget {
  final Order order;

  const MarkDeliveredSheet({super.key, required this.order});

  @override
  State<MarkDeliveredSheet> createState() => _MarkDeliveredSheetState();
}

class _MarkDeliveredSheetState extends State<MarkDeliveredSheet> {
  final _codeCtrl = TextEditingController();
  bool _paymentCollected = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Please enter the 4-digit confirmation code');
      return;
    }
    if (!_paymentCollected) {
      setState(
        () => _error = 'Please confirm payment has been collected before completing',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await DriverOrderService().completeDelivery(
        orderId: widget.order.id,
        enteredCode: code,
        paymentStatus: 'paid',
      );
      if (mounted) Navigator.pop(context, true);
    } on DeliveryCompletionException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Error completing delivery: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = widget.order.fulfillmentType == 'delivery';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDelivery ? 'Confirm Delivery' : 'Confirm Pickup Handover',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isDelivery
                ? 'Ask the customer at the door for their 4-digit confirmation code.'
                : 'Ask the customer to show their pickup code before handing over the parcel.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              labelText: '4-Digit Code',
              hintText: '••••',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _paymentCollected,
            onChanged: (v) => setState(() => _paymentCollected = v ?? false),
            title: Text(
              'Payment collected (${widget.order.paymentMethod == "cod" ? "Cash" : "Lipa Namba"})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Confirm & Complete Delivery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
