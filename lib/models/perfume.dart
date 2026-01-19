class Perfume {
  String? id;
  String name;
  int quantity;
  int initialQuantity; // ✅ Added for stock/revenue calculation
  String imageUrl; // Can be a local asset or network URL

  Perfume({
    this.id,
    required this.name,
    required this.quantity,
    required this.initialQuantity,
    required this.imageUrl,
  });

  // Factory method to create Perfume from Firestore map
  factory Perfume.fromMap(Map<String, dynamic> map, String id) {
    return Perfume(
      id: id,
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      initialQuantity: (map['initialQuantity'] ?? map['quantity'] ?? 0).toInt(),
      imageUrl: map['imageUrl'] ?? 'assets/images/placeholder.jpg',
    );
  }

  // Convert Perfume to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'initialQuantity': initialQuantity,
      'imageUrl': imageUrl,
    };
  }
}
