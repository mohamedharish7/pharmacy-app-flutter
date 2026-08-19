import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';

class MedicineTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineTile({
    super.key,
    required this.medicine,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final expiring = medicine.isExpiringSoon;
    final lowStock = medicine.isLowStock;

    Color tint = Colors.white;
    Color stripe = Colors.transparent;
    if (expiring && lowStock) {
      tint = const Color(0xFFFBEBDE);
      stripe = const Color(0xFFA53F37);
    } else if (expiring) {
      tint = const Color(0xFFF5E0DD);
      stripe = const Color(0xFFA53F37);
    } else if (lowStock) {
      tint = const Color(0xFFFAEED4);
      stripe = const Color(0xFFA67322);
    }

    final dateStr = DateFormat('MMM d, yyyy').format(medicine.expiryDate);
    final days = medicine.daysUntilExpiry;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBE3DF)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: stripe,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medicine.imagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(medicine.imagePath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFEEF3F1),
                            child: const Icon(Icons.medication_outlined, size: 20, color: Colors.black26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  medicine.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              Text(
                                '\u20b9${medicine.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(medicine.brand, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Exp: $dateStr', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              if (expiring) _badge(days < 0 ? 'expired' : '${days}d left', const Color(0xFFA53F37)),
                              Text('Qty: ${medicine.quantity}', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              if (lowStock) _badge('low', const Color(0xFFA67322)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: onSell,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                child: const Text('Sell'),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: onEdit,
                                tooltip: 'Edit',
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: onDelete,
                                tooltip: 'Delete',
                                color: Colors.red.shade700,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'monospace')),
    );
  }
}
