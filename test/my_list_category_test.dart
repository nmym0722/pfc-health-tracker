import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/models/food_master.dart';
import 'package:pfc_health_tracker/models/recipe.dart';

void main() {
  group('MyListCategory and Recipe Scale Tests', () {
    const egg = FoodMaster(
      id: 'food-egg',
      name: '鶏卵（全卵）',
      baseAmount: 1.0,
      unit: FoodUnit.piece,
      calories: 76.0,
      protein: 6.2,
      fat: 5.2,
      carbs: 0.2,
    );

    test('Recipeのカテゴリが正常にJSON保存・復元されること', () {
      final recipe = Recipe(
        id: 'test-recipe-1',
        name: 'ゆで卵 2個',
        servings: 1,
        category: MyListCategory.ingredient,
        ingredients: [
          const RecipeIngredient(food: egg, amount: 2.0),
        ],
        createdAt: DateTime.now(),
      );

      final json = recipe.toJson();
      expect(json['category'], equals('ingredient'));

      final restored = Recipe.fromJson(json);
      expect(restored.category, equals(MyListCategory.ingredient));
      expect(restored.name, equals('ゆで卵 2個'));
    });

    test('旧バージョンのcategoryなしJSONでも食材件数に応じて互換推論されること', () {
      final oldJson = {
        'id': 'old-single',
        'name': 'プロテイン',
        'servings': 1,
        'ingredients': [
          const RecipeIngredient(food: egg, amount: 1.0).toJson(),
        ],
        'createdAt': DateTime.now().toIso8601String(),
      };

      final restored = Recipe.fromJson(oldJson);
      // 食材が1件なので ingredient と推論
      expect(restored.category, equals(MyListCategory.ingredient));
    });

    test('分量割合（scale）による栄養価の正確なスケーリング', () {
      final singleRecipe = Recipe(
        id: 'test-single',
        name: '卵',
        servings: 1,
        category: MyListCategory.ingredient,
        ingredients: [
          const RecipeIngredient(food: egg, amount: 1.0),
        ],
        createdAt: DateTime.now(),
      );

      // 基準（1.0倍）
      expect(singleRecipe.caloriesPerServing, equals(76.0));
      expect(singleRecipe.proteinPerServing, equals(6.2));

      // 1.5倍スケール
      const scale15 = 1.5;
      expect(singleRecipe.caloriesPerServing * scale15, closeTo(114.0, 0.1));
      expect(singleRecipe.proteinPerServing * scale15, closeTo(9.3, 0.1));

      // 0.5倍スケール
      const scale05 = 0.5;
      expect(singleRecipe.caloriesPerServing * scale05, closeTo(38.0, 0.1));
      expect(singleRecipe.proteinPerServing * scale05, closeTo(3.1, 0.1));
    });
  });
}
