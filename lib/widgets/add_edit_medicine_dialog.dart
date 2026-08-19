import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final Medicine? medicine;
  const AddEditMedicineDialog({super.key, this.medicine});

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late final TextEditingController _fullName;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  DateTime? _expiryDate;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _fullName = TextEditingController(text: m?.fullName ?? '');
    _brand = TextEditingController(text: m?.brand ?? '');
    _quantity = TextEditingController(text: m != null ? m.quantity.toString() : '');
    _price = TextEditingController(text: m != null ? m.price.toStringAsFixed(2) : '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _expiryDate = m?.expiryDate;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _brand.dispose();
    _quantity.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      setState(() => _error = 'Please choose an expiry date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final medicine = Medicine(
      id: widget.medicine?.id ?? '',
      fullName: _fullName.text.trim(),
      notes: _notes.text.trim(),
      expiryDate: _expiryDate!,
      quantity: int.parse(_quantity.text.trim()),
      price: double.parse(_price.text.trim()),
      brand: _brand.text.trim(),
    );

    try {
      if (_isEdit) {
        await _api.updateMedicine(widget.medicine!.id, medicine);
      } else {
        await _api.addMedicine(medicine);
      }
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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit medicine' : 'Add medicine'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry date'),
                    child: Text(
                      _expiryDate == null
                          ? 'Select date'
                          : '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save medicine'),
        ),
      ],
    );
  }
}
