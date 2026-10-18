import 'food_master.dart';

class RecipeIngredient {
  final FoodMaster food;
  final double amount; // 使用量 (g, ml, 個等)

  const RecipeIngredient({
    required this.food,
    required this.amount,
  });

  double get calories => (food.calories / food.baseAmount) * amount;
  double get protein => (food.protein / food.baseAmount) * amount;
  double get fat => (food.fat / food.baseAmount) * amount;
  double get carbs => (food.carbs / food.baseAmount) * amount;

  RecipeIngredient copyWith({
    FoodMaster? food,
    double? amount,
  }) {
    return RecipeIngredient(
      food: food ?? this.food,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food': food.toJson(),
      'amount': amount,
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      food: FoodMaster.fromJson(json['food'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// マイリストの分類カテゴリ
enum MyListCategory {
  ingredient, // 食材・単品（プロテイン、オートミール、卵など）
  homeCooked, // 自炊レシピ（手料理、ボウル合算）
  diningOut,  // 外食メニュー（定番外食、定食、ラーメンなど）
}

extension MyListCategoryExtension on MyListCategory {
  String get label {
    switch (this) {
      case MyListCategory.ingredient:
        return '食材・単品';
      case MyListCategory.homeCooked:
        return '自炊レシピ';
      case MyListCategory.diningOut:
        return '外食メニュー';
    }
  }

  String get shortLabel {
    switch (this) {
      case MyListCategory.ingredient:
        return '食材';
      case MyListCategory.homeCooked:
        return '自炊';
      case MyListCategory.diningOut:
        return '外食';
    }
  }
}

class Recipe {
  final String id;
  final String name;
  final String? description;
  final int servings; // 人前
  final List<RecipeIngredient> ingredients;
  final MyListCategory category;
  final DateTime createdAt;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    this.servings = 1,
    required this.ingredients,
    this.category = MyListCategory.homeCooked,
    required this.createdAt,
  });

  double get totalCalories =>
      ingredients.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein =>
      ingredients.fold(0.0, (sum, item) => sum + item.protein);
  double get totalFat =>
      ingredients.fold(0.0, (sum, item) => sum + item.fat);
  double get totalCarbs =>
      ingredients.fold(0.0, (sum, item) => sum + item.carbs);

  double get caloriesPerServing => totalCalories / (servings > 0 ? servings : 1);
  double get proteinPerServing => totalProtein / (servings > 0 ? servings : 1);
  double get fatPerServing => totalFat / (servings > 0 ? servings : 1);
  double get carbsPerServing => totalCarbs / (servings > 0 ? servings : 1);

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    int? servings,
    List<RecipeIngredient>? ingredients,
    MyListCategory? category,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'servings': servings,
      'category': category.name,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final catName = json['category'] as String?;
    final ingredientsList = (json['ingredients'] as List<dynamic>)
        .map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
        .toList();

    MyListCategory cat;
    if (catName != null) {
      cat = MyListCategory.values.firstWhere(
        (c) => c.name == catName,
        orElse: () => MyListCategory.homeCooked,
      );
    } else {
      // 後方互換性：食材が1件のみなら単品食材、それ以外は自炊と自動推論
      cat = ingredientsList.length == 1
          ? MyListCategory.ingredient
          : MyListCategory.homeCooked;
    }

    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      servings: json['servings'] as int? ?? 1,
      category: cat,
      ingredients: ingredientsList,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
