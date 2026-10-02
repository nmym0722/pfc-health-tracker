import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfc_health_tracker/providers/user_provider.dart';
import 'package:pfc_health_tracker/providers/weight_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Weight Tracking & Adaptive Goal Recalculation Tests', () {
    test('過去日での体重追加・編集・削除とプロフィール目標の自動連動', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weightProvider.notifier);
      final initialLogs = container.read(weightProvider);
      final initialCount = initialLogs.length;

      // 1. 過去日付（2026-10-05）を指定して新しい体重 71.5kg を追加
      final pastDate = DateTime(2026, 10, 5);
      notifier.addWeightLog(71.5, date: pastDate, bodyFat: 18.2);

      var logs = container.read(weightProvider);
      expect(logs.length, equals(initialCount + 1));
      expect(logs.any((l) => l.weight == 71.5 && l.date == pastDate), isTrue);

      // 2. 最新日付（2026-10-10）で体重 70.8kg を追加 -> ユーザープロフィールの現在体重が 70.8kg に自動同期されること
      final futureDate = DateTime(2026, 10, 10);
      notifier.addWeightLog(70.8, date: futureDate);

      var user = container.read(userProvider);
      expect(user.currentWeight, equals(70.8));

      // 3. 編集テスト: 70.8kg のログを 70.5kg に更新
      final targetLog = container.read(weightProvider).firstWhere((l) => l.weight == 70.8);
      notifier.updateWeightLog(targetLog.id, weight: 70.5);

      user = container.read(userProvider);
      expect(user.currentWeight, equals(70.5));

      // 4. 削除テスト: 追加したログを削除
      notifier.deleteWeightLog(targetLog.id);
      logs = container.read(weightProvider);
      expect(logs.any((l) => l.id == targetLog.id), isFalse);
    });
  });
}
