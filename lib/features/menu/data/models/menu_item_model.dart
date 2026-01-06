import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final bool isAvailable;
  final String? imageUrl;
  final DateTime createdAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.imageUrl,
    required this.createdAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      isAvailable: json['is_available'] ?? true,
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'is_available': isAvailable,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, description, price, category, isAvailable, imageUrl, createdAt];
}
