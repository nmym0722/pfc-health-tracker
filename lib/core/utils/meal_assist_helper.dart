import '../../models/meal_record.dart';

/// 食事入力・編集・時短アシストに関するUI非依存の純粋ロジッククラス
class MealAssistHelper {
  const MealAssistHelper._();

  /// 現在時刻に応じてデフォルトの食事区分（朝/昼/夕/間食）を自動判定する
  /// - 05:00 〜 10:29 -> 朝食
  /// - 10:30 〜 14:59 -> 昼食
  /// - 15:00 〜 17:29 -> 間食
  /// - 17:30 〜 22:29 -> 夕食
  /// - 22:30 〜 04:59 -> 間食
  static MealType inferDefaultMealType([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();
    final minutes = now.hour * 60 + now.minute;

    if (minutes >= 5 * 60 && minutes < 10 * 60 + 30) {
      return MealType.breakfast;
    } else if (minutes >= 10 * 60 + 30 && minutes < 15 * 60) {
      return MealType.lunch;
    } else if (minutes >= 15 * 60 && minutes < 17 * 60 + 30) {
      return MealType.snack;
    } else if (minutes >= 17 * 60 + 30 && minutes < 22 * 60 + 30) {
      return MealType.dinner;
    } else {
      return MealType.snack;
    }
  }

  /// 記録済みMealItemの分量を変更し、カロリー・PFCを比例スケーリングした新しいMealItemを返す
  static MealItem scaleMealItem(MealItem item, double newAmount) {
    if (newAmount <= 0 || item.amount <= 0) {
      return item;
    }
    final ratio = newAmount / item.amount;
    return item.copyWith(
      amount: newAmount,
      calories: item.calories * ratio,
      protein: item.protein * ratio,
      fat: item.fat * ratio,
      carbs: item.carbs * ratio,
    );
  }

  /// 前日などの食事アイテムリストを別の日付向けに新しいIDでディープコピーする
  static List<MealItem> cloneMealItems(
    List<MealItem> sourceItems, {
    int? timestampMs,
  }) {
    final baseTs = timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    final Map<String, String> recipeBatchMap = {};

    return List<MealItem>.generate(sourceItems.length, (index) {
      final src = sourceItems[index];
      String? newRecipeId;
      if (src.recipeId != null && src.recipeId!.isNotEmpty) {
        newRecipeId = recipeBatchMap.putIfAbsent(
          src.recipeId!,
          () => 'recipe-copy-$baseTs-${recipeBatchMap.length}',
        );
      }
      return src.copyWith(
        id: 'item-copy-$baseTs-$index',
        recipeId: newRecipeId,
      );
    });
  }

  /// P・F・Cのグラム数からアトウォーター係数（P:4, F:9, C:4）で総カロリーを算出する
  static double calculateCaloriesFromPfc({
    required double protein,
    required double fat,
    required double carbs,
  }) {
    final p = protein < 0 ? 0.0 : protein;
    final f = fat < 0 ? 0.0 : fat;
    final c = carbs < 0 ? 0.0 : carbs;
    return p * 4.0 + f * 9.0 + c * 4.0;
  }

  /// 過去の全食事レコードから「最近食べた単品アイテム（重複名除去・最新順）」を抽出する
  static List<MealItem> extractRecentUniqueItems(
    List<MealRecord> allRecords, {
    int limit = 12,
  }) {
    if (allRecords.isEmpty) return const [];

    // 日付と作成日時の降順（新しい順）にソート
    final sortedRecords = [...allRecords]..sort((a, b) {
        final dateCmp = b.date.compareTo(a.date);
        if (dateCmp != 0) return dateCmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    final seenKeys = <String>{};
    final result = <MealItem>[];

    for (final record in sortedRecords) {
      for (final item in record.items.reversed) {
        // レシピ展開された個別食材ではなく、ユーザーが意識しやすい単位で重複排除
        final cleanName = item.cleanIngredientName.trim();
        if (cleanName.isEmpty) continue;
        final key = '$cleanName|${item.unit}';
        if (seenKeys.add(key)) {
          result.add(
            item.copyWith(
              name: cleanName,
              clearRecipeInfo: true,
            ),
          );
          if (result.length >= limit) {
            return result;
          }
        }
      }
    }

    return result;
  }
}
