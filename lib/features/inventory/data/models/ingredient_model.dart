import 'package:equatable/equatable.dart';

class IngredientModel extends Equatable {
  final String id;
  final String name;
  final bool isAvailable;
  final String? notes;

  const IngredientModel({
    required this.id,
    required this.name,
    this.isAvailable = true,
    this.notes,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'],
      name: json['name'],
      isAvailable: json['is_available'] ?? true,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'is_available': isAvailable,
        'notes': notes,
      };

  IngredientModel copyWith({
    String? id,
    String? name,
    bool? isAvailable,
    String? notes,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, name, isAvailable, notes];
}
