import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

class SellDialog extends StatefulWidget {
  final Medicine medicine;
  const SellDialog({super.key, required this.medicine});

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _api = ApiService();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _api.recordSale(
        medicineId: widget.medicine.id,
        quantitySold: int.parse(_quantityController.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    return AlertDialog(
      title: const Text('Record a sale'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '${med.quantity} unit(s) in stock \u00b7 \u20b9${med.price.toStringAsFixed(2)} each',
              style: const TextStyle(fontSize: 13, color: Colors.black54, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Quantity sold'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Enter at least 1';
                if (n > med.quantity) return 'Only ${med.quantity} in stock';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Confirm sale'),
        ),
      ],
    );
  }
}
