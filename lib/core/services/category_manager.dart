import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final bool isCustom;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'isCustom': isCustom,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        icon: Icons.category_rounded,
        isCustom: json['isCustom'] as bool? ?? true,
      );
}

class CategoryManager {
  static const List<CategoryItem> defaultCategories = [
    CategoryItem(id: 'food', name: 'Food & Dining', emoji: '🍔', icon: Icons.restaurant_rounded),
    CategoryItem(id: 'transport', name: 'Transport', emoji: '🚗', icon: Icons.directions_car_rounded),
    CategoryItem(id: 'groceries', name: 'Groceries', emoji: '🛒', icon: Icons.shopping_cart_rounded),
    CategoryItem(id: 'utilities', name: 'Utilities', emoji: '⚡', icon: Icons.bolt_rounded),
    CategoryItem(id: 'entertainment', name: 'Entertainment', emoji: '🎬', icon: Icons.movie_rounded),
    CategoryItem(id: 'health', name: 'Health & Care', emoji: '🏥', icon: Icons.medical_services_rounded),
    CategoryItem(id: 'salary', name: 'Salary', emoji: '💼', icon: Icons.work_rounded),
    CategoryItem(id: 'investment', name: 'Investment', emoji: '📈', icon: Icons.trending_up_rounded),
    CategoryItem(id: 'other', name: 'Other', emoji: '📝', icon: Icons.more_horiz_rounded),
  ];

  static CategoryItem getCategoryByName(String name) {
    return defaultCategories.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CategoryItem(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        emoji: '💰',
        icon: Icons.label_rounded,
      ),
    );
  }
}
