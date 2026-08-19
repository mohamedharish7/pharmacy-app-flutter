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

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String? ?? '',
      quantitySold: (json['quantitySold'] as num).toInt(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      saleDate: DateTime.parse(json['saleDate'] as String),
    );
  }
}
