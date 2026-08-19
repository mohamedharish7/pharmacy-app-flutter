class Medicine {
  final String id;
  final String fullName;
  final String notes;
  final DateTime expiryDate;
  final int quantity;
  final double price;
  final String brand;
  final String? imagePath;

  Medicine({
    required this.id,
    required this.fullName,
    required this.notes,
    required this.expiryDate,
    required this.quantity,
    required this.price,
    required this.brand,
    this.imagePath,
  });

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      fullName: map['fullName'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      brand: map['brand'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'notes': notes,
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'price': price,
      'brand': brand,
      'imagePath': imagePath,
    };
  }

  Medicine copyWith({
    String? fullName,
    String? notes,
    DateTime? expiryDate,
    int? quantity,
    double? price,
    String? brand,
    String? imagePath,
  }) {
    return Medicine(
      id: id,
      fullName: fullName ?? this.fullName,
      notes: notes ?? this.notes,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      brand: brand ?? this.brand,
      imagePath: imagePath ?? this.imagePath,
    );
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
