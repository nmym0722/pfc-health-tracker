import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/services/nutrition_ocr_service.dart';

void main() {
  group('NutritionOcrResult & Parsing Tests', () {
    test('100gあたり表示かつ内容量から合計が算出されている場合のパース検証', () {
      final jsonMap = {
        'food_name': '高たんぱくギリシャヨーグルト',
        'serving_unit': '1個(110g)当たり',
        'net_weight_g': 110.0,
        'calories': 92.0,
        'protein': 10.0,
        'fat': 0.0,
        'carbs': 12.5,
        'total_calories': 92.0,
        'total_protein': 10.0,
        'total_fat': 0.0,
        'total_carbs': 12.5,
      };

      final result = NutritionOcrResult.fromJson(jsonMap, jsonEncode(jsonMap));

      expect(result.foodName, '高たんぱくギリシャヨーグルト');
      expect(result.servingUnit, '1個(110g)当たり');
      expect(result.netWeightG, 110.0);
      expect(result.effectiveCalories, 92.0);
      expect(result.effectiveProtein, 10.0);
      expect(result.effectiveFat, 0.0);
      expect(result.effectiveCarbs, 12.5);
    });

    test('100g当たり表示で1包装全体のtotal値が存在する場合、effective値がtotalを優先すること', () {
      final jsonMap = {
        'food_name': 'プロテインスナック',
        'serving_unit': '100g当たり',
        'net_weight_g': 150.0,
        'calories': 400.0,
        'protein': 30.0,
        'fat': 12.0,
        'carbs': 42.0,
        'total_calories': 600.0,
        'total_protein': 45.0,
        'total_fat': 18.0,
        'total_carbs': 63.0,
      };

      final result = NutritionOcrResult.fromJson(jsonMap, jsonEncode(jsonMap));

      // 単位当たりではなく1包装全体の合計値が使われること
      expect(result.effectiveCalories, 600.0);
      expect(result.effectiveProtein, 45.0);
      expect(result.effectiveFat, 18.0);
      expect(result.effectiveCarbs, 63.0);
    });

    test('文字列混じりの数値やnullが安全にフォールバックされること', () {
      final jsonMap = {
        'food_name': null,
        'serving_unit': null,
        'net_weight_g': null,
        'calories': '250 kcal',
        'protein': '18.5g',
        'fat': '3.2 g',
        'carbs': '24.0g',
        'total_calories': null,
        'total_protein': null,
        'total_fat': null,
        'total_carbs': null,
      };

      final result = NutritionOcrResult.fromJson(jsonMap, jsonEncode(jsonMap));

      expect(result.foodName, isNull);
      expect(result.calories, 250.0);
      expect(result.protein, 18.5);
      expect(result.fat, 3.2);
      expect(result.carbs, 24.0);
      expect(result.effectiveCalories, 250.0);
    });
  });
}
