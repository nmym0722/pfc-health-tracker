enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return '朝食';
      case MealType.lunch:
        return '昼食';
      case MealType.dinner:
        return '夕食';
      case MealType.snack:
        return '間食';
    }
  }
}

class MealItem {
  final String id;
  final String name;
  final String? foodId;
  final String? recipeId;
  final double amount;
  final String unit;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const MealItem({
    required this.id,
    required this.name,
    this.foodId,
    this.recipeId,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'foodId': foodId,
      'recipeId': recipeId,
      'amount': amount,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      id: json['id'] as String,
      name: json['name'] as String,
      foodId: json['foodId'] as String?,
      recipeId: json['recipeId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }
}

class MealRecord {
  final String id;
  final DateTime date;
  final MealType type;
  final List<MealItem> items;
  final DateTime createdAt;

  const MealRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    required this.createdAt,
  });

  double get totalCalories => items.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.protein);
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.fat);
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.carbs);

  MealRecord copyWith({
    String? id,
    DateTime? date,
    MealType? type,
    List<MealItem>? items,
    DateTime? createdAt,
  }) {
    return MealRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    return MealRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: MealType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MealType.lunch,
      ),
      items: (json['items'] as List<dynamic>)
          .map((i) => MealItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
