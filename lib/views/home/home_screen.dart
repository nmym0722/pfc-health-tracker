import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/meal_record.dart';
import '../../providers/user_provider.dart';
import '../../providers/meal_provider.dart';
import 'widgets/pfc_summary_card.dart';
import 'widgets/calorie_balance_card.dart';
import 'widgets/meal_timeline_section.dart';
import '../meal_input/meal_input_screen.dart';
import '../profile/profile_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(userProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final meals = ref.watch(selectedDateMealsProvider);
    final totals = ref.watch(selectedDateTotalsProvider);
    final categoryCalories = ref.watch(selectedDateCategoryCaloriesProvider);

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateLabel = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(selectedDate);
    final shortDateLabel = DateFormat('M/d', 'ja_JP').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PFC トラッカー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '目標・プロフィール設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 日付ナビゲーションバー (前日・翌日・カレンダー選択・今日へ戻る)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    // 前日へ
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '前日へ',
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.subtract(const Duration(days: 1));
                      },
                    ),

                    // カレンダー & 日付表示（タップでカレンダーを開く）
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _pickDate(context, ref, selectedDate),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateLabel,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '今日',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 翌日へ
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '翌日へ',
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.add(const Duration(days: 1));
                      },
                    ),

                    // 今日へ戻るボタン (過去日/未来日を見ている時のみ表示)
                    if (!isToday)
                      TextButton(
                        onPressed: () {
                          final today = DateTime.now();
                          ref.read(selectedDateProvider.notifier).state =
                              DateTime(today.year, today.month, today.day);
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('今日へ'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. 円形カロリーチャート & PFCサマリーカード
            PfcSummaryCard(
              targetCalories: userProfile.goals.targetCalories,
              currentCalories: totals['calories']!,
              categoryCalories: categoryCalories,
              targetProtein: userProfile.goals.targetProtein,
              currentProtein: totals['protein']!,
              targetFat: userProfile.goals.targetFat,
              currentFat: totals['fat']!,
              targetCarbs: userProfile.goals.targetCarbs,
              currentCarbs: totals['carbs']!,
            ),
            const SizedBox(height: 16),

            // 週・月のカロリー収支 & チートデイ診断カード
            const CalorieBalanceCard(),
            const SizedBox(height: 24),

            // 3. 食事タイムラインヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday ? '本日の食事記録' : '$shortDateLabel の食事記録',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _openMealInput(context, MealType.breakfast, selectedDate);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('食事を追加'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 4. 食事タイムライン
            MealTimelineSection(
              meals: meals,
              onAddMealPressed: (type) => _openMealInput(context, type, selectedDate),
              onDeleteItemPressed: (recordId, itemId) {
                ref.read(mealProvider.notifier).removeMealItem(recordId, itemId);
              },
            ),
            const SizedBox(height: 80), // FAB用スペース
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMealInput(context, MealType.lunch, selectedDate),
        icon: const Icon(Icons.restaurant),
        label: Text(isToday ? '記録を追加' : '$shortDateLabel に記録'),
      ),
    );
  }

  // カレンダー日付選択
  Future<void> _pickDate(BuildContext context, WidgetRef ref, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state =
          DateTime(picked.year, picked.month, picked.day);
    }
  }

  // 食事入力画面を開く
  void _openMealInput(BuildContext context, MealType type, DateTime targetDate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealInputScreen(
          initialMealType: type,
          targetDate: targetDate,
          isModal: true,
        ),
      ),
    );
  }
}
