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
  final String? recipeName;
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
    this.recipeName,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  /// 関連するレシピ名を取得（recipeNameフィールド優先、未設定時はnameの末尾括弧から自動抽出）
  String? get associatedRecipeName {
    if (recipeName != null && recipeName!.trim().isNotEmpty) {
      return recipeName!.trim();
    }
    final match = RegExp(r'[\s]*[\(（]([^()（）]+)[\)）]$').firstMatch(name);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  /// レシピ名を除いた食材本来の名称（例: 鶏むね肉（皮なし）（蒸し鶏ボウル） -> 鶏むね肉（皮なし））
  String get cleanIngredientName {
    final rName = associatedRecipeName;
    if (rName == null) return name;
    return name.replaceFirst(RegExp(r'[\s]*[\(（]' + RegExp.escape(rName) + r'[\)）]$'), '').trim();
  }

  MealItem copyWith({
    String? id,
    String? name,
    String? foodId,
    String? recipeId,
    String? recipeName,
    bool clearRecipeInfo = false,
    double? amount,
    String? unit,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      foodId: foodId ?? this.foodId,
      recipeId: clearRecipeInfo ? null : (recipeId ?? this.recipeId),
      recipeName: clearRecipeInfo ? null : (recipeName ?? this.recipeName),
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'foodId': foodId,
      'recipeId': recipeId,
      'recipeName': recipeName,
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
      recipeName: json['recipeName'] as String?,
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
  /// その日の全食事記録が完了したか（動的TDEE適応の計算対象にするかどうかの判定）
  final bool isDayCompleted;

  const MealRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.items,
    required this.createdAt,
    this.isDayCompleted = true,
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
    bool? isDayCompleted,
  }) {
    return MealRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isDayCompleted: isDayCompleted ?? this.isDayCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'items': items.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isDayCompleted': isDayCompleted,
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
      isDayCompleted: json['isDayCompleted'] as bool? ?? true,
    );
  }
}
