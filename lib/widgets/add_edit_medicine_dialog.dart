import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../services/photo_storage_service.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final Medicine? medicine;
  const AddEditMedicineDialog({super.key, this.medicine});

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService.instance;
  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _photoStorage = PhotoStorageService();

  late final TextEditingController _fullName;
  late final TextEditingController _brand;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  DateTime? _expiryDate;

  String? _imagePath; // saved (permanent) photo path, if any
  List<String> _detectedLines = [];

  bool _saving = false;
  bool _scanning = false;
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
    _imagePath = m?.imagePath;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _brand.dispose();
    _quantity.dispose();
    _price.dispose();
    _notes.dispose();
    _ocr.dispose();
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

  Future<void> _scanMedicinePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (e) {
      _showError('Could not open camera/gallery: $e');
      return;
    }
    if (picked == null) return;

    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final savedPath = await _photoStorage.saveMedicinePhoto(File(picked.path));
      final lines = await _ocr.recognizeCandidateLines(File(savedPath));

      setState(() {
        _imagePath = savedPath;
        _detectedLines = lines.take(8).toList();
        _scanning = false;
      });

      if (lines.isNotEmpty) {
        _fullName.text = lines[0];
        if (lines.length > 1) _brand.text = lines[1];
        _showSnack('Photo scanned — check Name/Brand below and fix if needed.');
      } else {
        _showSnack("Couldn't read any text from that photo. Try better lighting, or type it in manually.");
      }
    } catch (e) {
      setState(() => _scanning = false);
      _showError('Scan failed: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
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
      imagePath: _imagePath,
    );

    try {
      if (_isEdit) {
        await _db.updateMedicine(widget.medicine!.id, medicine);
      } else {
        await _db.addMedicine(medicine);
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
                _buildPhotoScanArea(),
                const SizedBox(height: 14),
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
                if (_detectedLines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetectedLinesPicker(),
                ],
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

  Widget _buildPhotoScanArea() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _imagePath != null
              ? Image.file(File(_imagePath!), width: 64, height: 64, fit: BoxFit.cover)
              : Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFEEF3F1),
                  child: const Icon(Icons.medication_outlined, color: Colors.black38),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _scanning ? null : _scanMedicinePhoto,
            icon: _scanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(_scanning
                ? 'Reading photo…'
                : (_imagePath == null ? 'Scan medicine photo' : 'Rescan photo')),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedLinesPicker() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBE3DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detected text — tap to use for a field:',
            style: TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ..._detectedLines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () => setState(() => _fullName.text = line),
                      child: const Text('Name', style: TextStyle(fontSize: 11.5)),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      onPressed: () => setState(() => _brand.text = line),
                      child: const Text('Brand', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
