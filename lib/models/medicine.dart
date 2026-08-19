class Medicine {
  final String id;
  final String fullName;
  final String notes;
  final DateTime expiryDate;
  final int quantity;
  final double price;
  final String brand;

  Medicine({
    required this.id,
    required this.fullName,
    required this.notes,
    required this.expiryDate,
    required this.quantity,
    required this.price,
    required this.brand,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      quantity: (json['quantity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      brand: json['brand'] as String? ?? '',
    );
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'fullName': fullName,
      'notes': notes,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'price': price,
      'brand': brand,
    };
  }

  int get daysUntilExpiry {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiryOnly.difference(todayOnly).inDays;
  }

  bool get isExpiringSoon => daysUntilExpiry < 30;
  bool get isLowStock => quantity < 10;
}
