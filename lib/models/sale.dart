class Sale {
  final String id;
  final String medicineId;
  final String medicineName;
  final int quantitySold;
  final double unitPrice;
  final double totalAmount;
  final DateTime saleDate;

  Sale({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.quantitySold,
    required this.unitPrice,
    required this.totalAmount,
    required this.saleDate,
  });

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      medicineId: map['medicineId'] as String,
      medicineName: map['medicineName'] as String? ?? '',
      quantitySold: (map['quantitySold'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      saleDate: DateTime.parse(map['saleDate'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantitySold': quantitySold,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'saleDate': saleDate.toIso8601String(),
    };
  }
}
