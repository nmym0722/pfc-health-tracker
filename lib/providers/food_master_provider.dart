import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/default_foods.dart';
import '../models/food_master.dart';
import '../models/recipe.dart';
import '../services/storage_service.dart';

class FoodMasterNotifier extends StateNotifier<List<FoodMaster>> {
  FoodMasterNotifier() : super(DefaultFoods.list);

  void addCustomFood(FoodMaster food) {
    state = [...state, food];
  }
}

final foodMasterProvider = StateNotifierProvider<FoodMasterNotifier, List<FoodMaster>>((ref) {
  return FoodMasterNotifier();
});

class RecipeNotifier extends StateNotifier<List<Recipe>> {
  RecipeNotifier({List<Recipe>? initial}) : super(initial ?? _initialRecipes);

  static List<Recipe> get _initialRecipes {
    final chicken = DefaultFoods.list.firstWhere((f) => f.id == 'food-chicken-breast');
    final broccoli = DefaultFoods.list.firstWhere((f) => f.id == 'food-broccoli');
    final rice = DefaultFoods.list.firstWhere((f) => f.id == 'food-white-rice');

    return [
      Recipe(
        id: 'recipe-sample-1',
        name: '蒸し鶏とブロッコリーの筋肉ボウル',
        description: '高タンパク・低脂質の減量定番メニュー',
        servings: 1,
        ingredients: [
          RecipeIngredient(food: chicken, amount: 150.0),
          RecipeIngredient(food: broccoli, amount: 100.0),
          RecipeIngredient(food: rice, amount: 150.0),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  void addRecipe(Recipe recipe) {
    state = [...state, recipe];
    StorageService.saveRecipes(state);
  }

  void removeRecipe(String recipeId) {
    state = state.where((r) => r.id != recipeId).toList();
    StorageService.saveRecipes(state);
  }

  void clearAll() {
    state = [];
    StorageService.saveRecipes(state);
  }
}

final recipeProvider = StateNotifierProvider<RecipeNotifier, List<Recipe>>((ref) {
  return RecipeNotifier();
});
