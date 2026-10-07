import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/models/dining_preset.dart';

void main() {
  group('DiningPreset Nutrition Calculation Tests', () {
    test('普通（regular）選択時は基準値通りのPFCと整合したカロリーが算出される', () {
      final ramen = DiningPreset.defaultPresets.firstWhere((p) => p.id == 'dining-ramen-tonkotsu');
      final result = ramen.calculateNutrition(OilIntensity.regular);

      expect(result.protein, equals(ramen.baseProtein));
      expect(result.fat, equals(ramen.baseFat));
      expect(result.carbs, equals(ramen.baseCarbs));

      final expectedCal = (result.protein * 4) + (result.fat * 9) + (result.carbs * 4);
      expect(result.calories, closeTo(expectedCal, 0.1));
    });

    test('さっぱり（light）選択時は脂質が25%カットされ、カロリーが大幅に減少する', () {
      final shogayaki = DiningPreset.defaultPresets.firstWhere((p) => p.id == 'dining-shogayaki');
      final regularResult = shogayaki.calculateNutrition(OilIntensity.regular);
      final lightResult = shogayaki.calculateNutrition(OilIntensity.light);

      expect(lightResult.protein, equals(regularResult.protein)); // タンパク質は据え置き
      expect(lightResult.fat, closeTo(regularResult.fat * 0.75, 0.1)); // 脂質-25%
      expect(lightResult.carbs, closeTo(regularResult.carbs * 0.95, 0.1));
      expect(lightResult.calories, lessThan(regularResult.calories));
    });

    test('ガッツリ（heavy）選択時は脂質が45%増量され、背脂・油多めのカロリーが反映される', () {
      final karaage = DiningPreset.defaultPresets.firstWhere((p) => p.id == 'dining-karaage');
      final regularResult = karaage.calculateNutrition(OilIntensity.regular);
      final heavyResult = karaage.calculateNutrition(OilIntensity.heavy);

      expect(heavyResult.protein, equals(regularResult.protein));
      expect(heavyResult.fat, closeTo(regularResult.fat * 1.45, 0.1)); // 脂質+45%
      expect(heavyResult.calories, greaterThan(regularResult.calories));
    });
  });

  group('AlcoholPreset Calculation Tests', () {
    test('ハイボールは糖質0gであり、アルコール由来（約7kcal/g）のカロリーが正しく設定されている', () {
      final highball = AlcoholPreset.defaultList.firstWhere((a) => a.id == 'alc-highball');
      expect(highball.carbsGrams, equals(0.0));
      expect(highball.alcoholGrams, greaterThan(15.0));
      expect(highball.calories, closeTo(138.0, 1.0));
    });

    test('生ビールはアルコール純重量と糖質の両方からエネルギーが構成されている', () {
      final beer = AlcoholPreset.defaultList.firstWhere((a) => a.id == 'alc-beer');
      expect(beer.carbsGrams, greaterThan(10.0));
      expect(beer.alcoholGrams, equals(16.0));
      expect(beer.calories, equals(160.0));
    });
  });
}
