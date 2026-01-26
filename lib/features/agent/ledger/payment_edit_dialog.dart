import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/payment.dart';

/// Dialog for agents to request a payment edit (Point 8)
class PaymentEditDialog extends StatefulWidget {
  final Payment payment;

  const PaymentEditDialog({super.key, required this.payment});

  @override
  State<PaymentEditDialog> createState() => _PaymentEditDialogState();
}

class _PaymentEditDialogState extends State<PaymentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.payment.amountPaid.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text(
        'Request Payment Edit',
        style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.agentTextColor),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.agentPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: AppTheme.agentPrimaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Original: GHC ${widget.payment.amountPaid.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.agentTextColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              controller: _amountController,
              label: 'New Amount',
              hint: '0.00',
              icon: Icons.payments_rounded,
              prefixText: 'GHC ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter new amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _reasonController,
              label: 'Reason for Edit',
              hint: 'Explain why this payment needs correction...',
              icon: Icons.note_rounded,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a reason';
                }
                if (value.trim().length < 10) {
                  return 'Reason must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.agentAccentSync.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will create a request for Admin approval. The original payment will not be modified until approved.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.agentPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.agentTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade300),
            prefixText: prefixText,
            prefixIcon: Icon(icon, color: AppTheme.agentPrimaryColor, size: 18),
            filled: true,
            fillColor: AppTheme.agentInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // This will be called from the parent widget with a WidgetRef
      Navigator.pop(context, {
        'paymentId': widget.payment.id,
        'originalAmount': widget.payment.amountPaid,
        'newAmount': double.parse(_amountController.text),
        'reason': _reasonController.text.trim(),
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }
}
