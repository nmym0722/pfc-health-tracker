enum FoodUnit { g, ml, piece, serving, tablespoon, teaspoon }

class FoodMaster {
  final String id;
  final String name;
  final String? brand;
  final double baseAmount; // 例: 100.0
  final FoodUnit unit;
  final double calories;   // 基準量あたりのkcal
  final double protein;    // 基準量あたりのタンパク質 (g)
  final double fat;        // 基準量あたりの脂質 (g)
  final double carbs;      // 基準量あたりの炭水化物 (g)
  final String? category;  // 肉類, 野菜類, 穀物等
  final bool isCustom;     // ユーザー追加フラグ

  const FoodMaster({
    required this.id,
    required this.name,
    this.brand,
    required this.baseAmount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.category,
    this.isCustom = false,
  });

  String get unitLabel {
    switch (unit) {
      case FoodUnit.g:
        return 'g';
      case FoodUnit.ml:
        return 'ml';
      case FoodUnit.piece:
        return '個';
      case FoodUnit.serving:
        return '食';
      case FoodUnit.tablespoon:
        return '大さじ';
      case FoodUnit.teaspoon:
        return '小さじ';
    }
  }

  /// 基準分量表示 (例: 100g, 1個, 1食, 大さじ1, 小さじ1)
  String get baseAmountLabel {
    final amountStr = baseAmount == baseAmount.toInt()
        ? baseAmount.toInt().toString()
        : baseAmount.toString();
    if (unit == FoodUnit.tablespoon || unit == FoodUnit.teaspoon) {
      return '$unitLabel$amountStr';
    }
    return '$amountStr$unitLabel';
  }

  FoodMaster copyWith({
    String? id,
    String? name,
    String? brand,
    double? baseAmount,
    FoodUnit? unit,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    String? category,
    bool? isCustom,
  }) {
    return FoodMaster(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      baseAmount: baseAmount ?? this.baseAmount,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'baseAmount': baseAmount,
      'unit': unit.name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'category': category,
      'isCustom': isCustom,
    };
  }

  factory FoodMaster.fromJson(Map<String, dynamic> json) {
    return FoodMaster(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      baseAmount: (json['baseAmount'] as num).toDouble(),
      unit: FoodUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => FoodUnit.g,
      ),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      category: json['category'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}
