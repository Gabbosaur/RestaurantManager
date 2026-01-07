import 'package:equatable/equatable.dart';

class MenuItemModel extends Equatable {
  final String id;
  final String name;
  final String? nameZh; // nome in cinese per la cucina
  final String? description;
  final double price;
  final String category;
  final bool isAvailable;
  final String? ingredientKey;
  final String? imageUrl;
  final DateTime createdAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.nameZh,
    this.description,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.ingredientKey,
    this.imageUrl,
    required this.createdAt,
  });

  /// Ritorna il nome in cinese se disponibile, altrimenti il nome italiano
  String get displayNameZh => nameZh ?? name;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'],
      nameZh: json['name_zh'],
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      isAvailable: json['is_available'] ?? true,
      ingredientKey: json['ingredient_key'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_zh': nameZh,
        'description': description,
        'price': price,
        'category': category,
        'is_available': isAvailable,
        'ingredient_key': ingredientKey,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? nameZh,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    String? ingredientKey,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameZh: nameZh ?? this.nameZh,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      ingredientKey: ingredientKey ?? this.ingredientKey,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, nameZh, description, price, category, isAvailable, ingredientKey, imageUrl, createdAt];
}
