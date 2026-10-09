import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/default_foods.dart';
import '../models/food_master.dart';
import '../models/recipe.dart';
import '../services/storage_service.dart';

class FoodMasterNotifier extends StateNotifier<List<FoodMaster>> {
  FoodMasterNotifier({List<FoodMaster>? initial}) : super(initial ?? DefaultFoods.list);

  void addFood(FoodMaster food) {
    state = [...state, food];
    StorageService.saveFoodMasters(state);
  }

  void updateFood(FoodMaster updatedFood) {
    state = state.map((f) => f.id == updatedFood.id ? updatedFood : f).toList();
    StorageService.saveFoodMasters(state);
  }

  void deleteFood(String foodId) {
    state = state.where((f) => f.id != foodId).toList();
    StorageService.saveFoodMasters(state);
  }

  void resetToDefaults() {
    state = DefaultFoods.list;
    StorageService.saveFoodMasters(state);
  }

  void toggleFavorite(String foodId) {
    state = state.map((f) {
      if (f.id == foodId) {
        return f.copyWith(isFavorite: !f.isFavorite);
      }
      return f;
    }).toList();
    StorageService.saveFoodMasters(state);
  }

  // 互換性維持
  void addCustomFood(FoodMaster food) => addFood(food);
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
    final whey = DefaultFoods.list.firstWhere(
      (f) => f.id == 'food-protein-powder',
      orElse: () => chicken,
    );

    return [
      // 1. 自炊レシピ（手料理ボウル合算）
      Recipe(
        id: 'recipe-sample-1',
        name: '蒸し鶏とブロッコリーの筋肉ボウル',
        description: '高タンパク・低脂質の減量定番メニュー',
        servings: 1,
        category: MyListCategory.homeCooked,
        ingredients: [
          RecipeIngredient(food: chicken, amount: 150.0),
          RecipeIngredient(food: broccoli, amount: 100.0),
          RecipeIngredient(food: rice, amount: 150.0),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      // 2. 食材・単品（分量割合を調整しやすい）
      Recipe(
        id: 'recipe-sample-single-chicken',
        name: '鶏むね肉（皮なし・蒸し/茹で）',
        description: '高タンパク減量の基本食材（基準100g）',
        servings: 1,
        category: MyListCategory.ingredient,
        ingredients: [
          RecipeIngredient(food: chicken, amount: 100.0),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Recipe(
        id: 'recipe-sample-single-protein',
        name: 'ホエイプロテイン（1食分）',
        description: 'トレーニング後の急速補給',
        servings: 1,
        category: MyListCategory.ingredient,
        ingredients: [
          RecipeIngredient(food: whey, amount: 30.0),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      // 3. 外食メニュー（定番外食）
      Recipe(
        id: 'recipe-sample-dining-shogayaki',
        name: '豚生姜焼き定食（ご飯普通盛）',
        description: 'よく行く定食屋の定番',
        servings: 1,
        category: MyListCategory.diningOut,
        ingredients: const [
          RecipeIngredient(
            food: FoodMaster(
              id: 'food-dining-shogayaki-master',
              name: '豚生姜焼き定食',
              baseAmount: 1.0,
              unit: FoodUnit.serving,
              calories: 780.0,
              protein: 30.0,
              fat: 28.0,
              carbs: 98.0,
              category: '外食',
              isCustom: true,
            ),
            amount: 1.0,
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
