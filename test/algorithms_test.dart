import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/core/algorithms/weight_ema.dart';
import 'package:pfc_health_tracker/core/algorithms/tdee_adaptation.dart';
import 'package:pfc_health_tracker/core/algorithms/refeed_manager.dart';
import 'package:pfc_health_tracker/core/algorithms/guardrails.dart';

void main() {
  group('WeightEmaCalculator Tests', () {
    test('空のリストの場合は空リストを返す', () {
      final result = WeightEmaCalculator.calculateEmaSeries([]);
      expect(result.isEmpty, isTrue);
    });

    test('初日は実測値とEMAが一致する', () {
      final points = [
        WeightPoint(date: DateTime(2026, 10, 1), weight: 70.0),
      ];
      final result = WeightEmaCalculator.calculateEmaSeries(points);
      expect(result.length, 1);
      expect(result.first.emaWeight, 70.0);
    });

    test('チート翌日の急増に対して重み減衰が適用され、EMAが急騰しない', () {
      final points = [
        WeightPoint(date: DateTime(2026, 10, 1), weight: 70.0),
        WeightPoint(date: DateTime(2026, 10, 2), weight: 69.8),
        WeightPoint(date: DateTime(2026, 10, 3), weight: 69.6),
        // 4日目: チート翌日で水分により+1.5kg急増 (71.1kg)
        WeightPoint(date: DateTime(2026, 10, 4), weight: 71.1, isPostCheatDay: true),
      ];

      final resultWithDamping = WeightEmaCalculator.calculateEmaSeries(points);
      final lastEma = resultWithDamping.last.emaWeight;

      // 重み減衰が効いているため、EMAは70.0未満に強く抑えられているはず
      expect(lastEma < 70.0, isTrue);
    });

    test('欠損日（測定スキップ）があっても時間経過に応じた平滑化が行われる', () {
      final points = [
        WeightPoint(date: DateTime(2026, 10, 1), weight: 70.0),
        // 3日間測定なし
        WeightPoint(date: DateTime(2026, 10, 4), weight: 68.0),
      ];

      final result = WeightEmaCalculator.calculateEmaSeries(points);
      expect(result.length, 2);
      expect(result[1].emaWeight < 70.0, isTrue);
      expect(result[1].emaWeight > 68.0, isTrue);
    });
  });

  group('TdeeAdaptationCalculator Tests', () {
    test('データ不足（7日未満）の場合は適応をスキップする', () {
      final baseDate = DateTime(2026, 10, 1);
      final emaPoints = [
        WeightEmaPoint(date: baseDate, rawWeight: 70.0, emaWeight: 70.0),
      ];
      final intakes = [
        DailyIntakeLog(date: baseDate, caloriesConsumed: 2000.0),
      ];

      final res = TdeeAdaptationCalculator.calculateAdaptedTdee(
        currentTdee: 2200.0,
        intakeLogs: intakes,
        emaPoints: emaPoints,
      );

      expect(res.isReliable, isFalse);
      expect(res.adaptedTdee, 2200.0);
    });

    test('体重が減少しない場合、実効TDEEが下方修正され、週最大クランプ（±150kcal）が作動する', () {
      final baseDate = DateTime(2026, 10, 1);
      final emaPoints = <WeightEmaPoint>[];
      final intakes = <DailyIntakeLog>[];

      // 14日間、1800kcal摂取しているのに体重が全く減らない（傾き0）
      for (int i = 0; i < 14; i++) {
        final d = baseDate.add(Duration(days: i));
        emaPoints.add(WeightEmaPoint(date: d, rawWeight: 70.0, emaWeight: 70.0));
        intakes.add(DailyIntakeLog(date: d, caloriesConsumed: 1800.0));
      }

      // 現在設定TDEEが 2200kcal の場合、実効は1800kcalと推計されるが、クランプで2050kcal (-150kcal) に制限される
      final res = TdeeAdaptationCalculator.calculateAdaptedTdee(
        currentTdee: 2200.0,
        intakeLogs: intakes,
        emaPoints: emaPoints,
      );

      expect(res.isReliable, isTrue);
      expect(res.rawEstimatedTdee, 1800.0);
      expect(res.adaptedTdee, 2050.0); // 2200 - 150 = 2050
    });
  });

  group('RefeedManager Tests', () {
    test('目標先行時（0.5kgリード）、浮いたエネルギーの50%が全量炭水化物として解放される', () {
      final decision = RefeedManager.evaluateRefeed(
        currentEmaWeight: 69.5,
        plannedTargetWeight: 70.0, // 0.5kg 先行
        baseTargetCalories: 1800.0,
        currentTdee: 2200.0,
        baseProteinGrams: 140.0,
        baseFatGrams: 45.0,
        baseCarbsGrams: 200.0,
      );

      expect(decision.type, RefeedType.performanceBonus);
      expect(decision.isEligible, isTrue);
      // 0.5kg * 7200 * 0.5 = 1800kcal (キャップ1500kcalでクランプ)
      expect(decision.extraCalories, 1500.0);
      expect(decision.extraCarbsGrams, 375.0); // 1500 / 4
      // タンパク質と脂質は維持されていること
      expect(decision.targetProteinGrams, 140.0);
      expect(decision.targetFatGrams, 45.0);
    });

    test('計画的リフィード日は維持カロリーまで安全に解放される', () {
      final decision = RefeedManager.evaluateRefeed(
        currentEmaWeight: 70.0,
        plannedTargetWeight: 70.0,
        baseTargetCalories: 1800.0,
        currentTdee: 2200.0,
        baseProteinGrams: 140.0,
        baseFatGrams: 45.0,
        baseCarbsGrams: 200.0,
        isScheduledRefeedDay: true,
      );

      expect(decision.type, RefeedType.scheduled);
      expect(decision.isEligible, isTrue);
      expect(decision.extraCalories, 400.0); // 2200 - 1800 = 400
      expect(decision.totalCalories, 2200.0);
    });
  });

  group('SafetyGuardrails Tests', () {
    test('開始後10日目は初期ウォームアップ期間としてマスクされる', () {
      final startDate = DateTime(2026, 10, 1);
      final evalDate = DateTime(2026, 10, 11); // 10日後

      final result = SafetyGuardrails.evaluate(
        startDate: startDate,
        evaluationDate: evalDate,
        rawCalculatedTargetCalories: 1500.0,
        bmr: 1400.0,
        recentEmaPoints: [],
      );

      expect(result.isWarmupActive, isTrue);
    });

    test('目標カロリーがBMRを下回る場合、BMRで下限防衛され、期日延長サジェストが出る', () {
      final startDate = DateTime(2026, 9, 1);
      final evalDate = DateTime(2026, 10, 1); // 30日後（ウォームアップ終了）

      final result = SafetyGuardrails.evaluate(
        startDate: startDate,
        evaluationDate: evalDate,
        rawCalculatedTargetCalories: 1200.0, // 危険な低カロリー
        bmr: 1450.0,
        recentEmaPoints: [],
      );

      expect(result.isBmrFloorActive, isTrue);
      expect(result.safeTargetCalories, 1450.0);
      expect(result.suggestExtendDeadline, isTrue);
    });
  });
}
