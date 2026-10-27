import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/meal_assist_helper.dart';
import '../../models/food_master.dart';
import '../../models/meal_record.dart';
import '../../models/recipe.dart';
import '../../providers/food_master_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/refeed_provider.dart';
import 'widgets/pfc_summary_card.dart';
import 'widgets/calorie_balance_card.dart';
import 'widgets/meal_timeline_section.dart';
import 'widgets/refeed_proposal_card.dart';
import 'widgets/guardrail_alert_banner.dart';
import 'widgets/remaining_pfc_suggestion_card.dart';
import 'widgets/quick_weight_entry_bar.dart';
import '../meal_input/meal_input_screen.dart';
import '../profile/profile_settings_screen.dart';
import '../common/recipe_group_selector.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final effectiveGoals = ref.watch(effectiveDailyGoalsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final meals = ref.watch(selectedDateMealsProvider);
    final allMeals = ref.watch(mealProvider);
    final totals = ref.watch(selectedDateTotalsProvider);
    final categoryCalories = ref.watch(selectedDateCategoryCaloriesProvider);
    final allFoods = ref.watch(foodMasterProvider);
    final allRecipes = ref.watch(recipeProvider);

    final prevDate = selectedDate.subtract(const Duration(days: 1));
    final previousDayMeals = allMeals
        .where((m) =>
            m.date.year == prevDate.year &&
            m.date.month == prevDate.month &&
            m.date.day == prevDate.day)
        .toList();

    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateLabel = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(selectedDate);
    final shortDateLabel = DateFormat('M/d', 'ja_JP').format(selectedDate);
    final defaultMealType = MealAssistHelper.inferDefaultMealType(now);

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
            const SizedBox(height: 10),

            // クイック体重記録バー（未記録時は±0.1kgステッパーで即記録可能）
            QuickWeightEntryBar(selectedDate: selectedDate),

            // 安全ガードレール警告・対話バナー（停滞期プラトー・BMR下限割れリスク）
            const GuardrailAlertBanner(),

            // リフィード（ハイカーボデイ）専用提案カード
            const RefeedProposalCard(),
            const SizedBox(height: 8),

            // 2. 円形カロリーチャート & PFCサマリーカード（リフィード適用連動）
            PfcSummaryCard(
              targetCalories: effectiveGoals.targetCalories,
              currentCalories: totals['calories']!,
              categoryCalories: categoryCalories,
              targetProtein: effectiveGoals.targetProtein,
              currentProtein: totals['protein']!,
              targetFat: effectiveGoals.targetFat,
              currentFat: totals['fat']!,
              targetCarbs: effectiveGoals.targetCarbs,
              currentCarbs: totals['carbs']!,
            ),
            const SizedBox(height: 16),

            // 3. 食事タイムライン（アプリ起動後すぐに確認・追加可能）
            Text(
              isToday ? '本日の食事記録' : '$shortDateLabel の食事記録',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            MealTimelineSection(
              meals: meals,
              previousDayMeals: previousDayMeals,
              onAddMealPressed: (type) => _openMealInput(context, type, selectedDate),
              onDeleteItemPressed: (recordId, itemId) {
                ref.read(mealProvider.notifier).removeMealItem(recordId, itemId);
              },
              onDeleteItemsPressed: (recordId, itemIds) {
                ref.read(mealProvider.notifier).removeMealItems(recordId, itemIds);
              },
              onUpdateItemAmountPressed: (recordId, itemId, newAmount) {
                ref.read(mealProvider.notifier).updateMealItemAmount(recordId, itemId, newAmount);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分量を更新し、カロリー・PFCを再計算しました')),
                );
              },
              onCopyPreviousMealPressed: (type) {
                final copiedCount = ref.read(mealProvider.notifier).copyMealFromDate(
                      sourceDate: prevDate,
                      targetDate: selectedDate,
                      type: type,
                    );
                if (copiedCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('前日の${type.label}（$copiedCount品）をコピーしました')),
                  );
                }
              },
              onSaveMealAsRecipePressed: (record) {
                _showSaveMealRecordAsRecipeDialog(context, ref, record);
              },
            ),
            const SizedBox(height: 20),

            // 4. 残りPFC逆算アシストカード（ワンタップ食材・マイリスト提案）
            RemainingPfcSuggestionCard(
              targetCalories: effectiveGoals.targetCalories,
              currentCalories: totals['calories']!,
              targetProtein: effectiveGoals.targetProtein,
              currentProtein: totals['protein']!,
              targetFat: effectiveGoals.targetFat,
              currentFat: totals['fat']!,
              targetCarbs: effectiveGoals.targetCarbs,
              currentCarbs: totals['carbs']!,
              foods: allFoods,
              recipes: allRecipes,
              defaultMealType: defaultMealType,
              onAddSuggestedFood: (portion, mealType) {
                final item = MealItem(
                  id: 'item-${DateTime.now().millisecondsSinceEpoch}-${portion.food.id}',
                  name: portion.food.name,
                  foodId: portion.food.id,
                  amount: portion.recommendedAmount,
                  unit: portion.food.unitLabel,
                  calories: portion.calories,
                  protein: portion.protein,
                  fat: portion.fat,
                  carbs: portion.carbs,
                );
                ref.read(mealProvider.notifier).addMealItem(
                      date: selectedDate,
                      type: mealType,
                      item: item,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${mealType.label}に「${portion.food.name} (${portion.recommendedAmount.round()}${portion.food.unitLabel})」を追加しました',
                    ),
                  ),
                );
              },
              onAddSuggestedRecipe: (recipe, mealType) {
                final batchId = 'recipe-${DateTime.now().millisecondsSinceEpoch}-${recipe.id}';
                final items = recipe.ingredients.map((ing) {
                  final perAmt = ing.amount / recipe.servings;
                  final ratio = perAmt / ing.food.baseAmount;
                  return MealItem(
                    id: 'item-${DateTime.now().millisecondsSinceEpoch}-${ing.food.id}',
                    name: '${ing.food.name} (${recipe.name})',
                    foodId: ing.food.id,
                    recipeId: batchId,
                    recipeName: recipe.name,
                    amount: perAmt,
                    unit: ing.food.unitLabel,
                    calories: ing.food.calories * ratio,
                    protein: ing.food.protein * ratio,
                    fat: ing.food.fat * ratio,
                    carbs: ing.food.carbs * ratio,
                  );
                }).toList();
                ref.read(mealProvider.notifier).addMealItems(
                      date: selectedDate,
                      type: mealType,
                      items: items,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${mealType.label}に「${recipe.name}」を追加しました'),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 5. 週・月のカロリー収支 & 代謝適応サマリーカード
            const CalorieBalanceCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // タイムラインの食事ブロックをそのままマイレシピとして保存するダイアログ
  void _showSaveMealRecordAsRecipeDialog(
    BuildContext context,
    WidgetRef ref,
    MealRecord record,
  ) {
    final nameController = TextEditingController(
      text: '定番の${record.type.label}セット',
    );
    final descController = TextEditingController();
    MyListCategory category = MyListCategory.homeCooked;
    String group = '自炊';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('${record.type.label}をマイレシピに保存'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'マイレシピ名 *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'メモ (任意)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RecipeGroupSelector(
                      selectedGroup: group,
                      onGroupChanged: (g) {
                        setDialogState(() {
                          group = g;
                          if (g == '食材') {
                            category = MyListCategory.ingredient;
                          } else if (g == '外食') {
                            category = MyListCategory.diningOut;
                          } else {
                            category = MyListCategory.homeCooked;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '含まれる食品 (${record.items.length}品 / 合計 ${record.totalCalories.round()} kcal)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final allFoods = ref.read(foodMasterProvider);
                    final ingredients = record.items.map((item) {
                      final matchedFood = item.foodId != null
                          ? allFoods.where((f) => f.id == item.foodId).firstOrNull
                          : null;
                      if (matchedFood != null) {
                        return RecipeIngredient(
                          food: matchedFood,
                          amount: item.amount,
                        );
                      }
                      final customFood = FoodMaster(
                        id: 'food-from-meal-${DateTime.now().millisecondsSinceEpoch}-${item.id}',
                        name: item.cleanIngredientName,
                        baseAmount: item.amount > 0 ? item.amount : 1.0,
                        unit: FoodUnit.serving,
                        calories: item.calories,
                        protein: item.protein,
                        fat: item.fat,
                        carbs: item.carbs,
                        category: 'その他',
                        isCustom: true,
                      );
                      return RecipeIngredient(
                        food: customFood,
                        amount: item.amount > 0 ? item.amount : 1.0,
                      );
                    }).toList();

                    final newRecipe = Recipe(
                      id: 'recipe-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      servings: 1,
                      category: category,
                      customGroup: group,
                      ingredients: ingredients,
                      createdAt: DateTime.now(),
                    );

                    ref.read(recipeProvider.notifier).addRecipe(newRecipe);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('「$name」をマイレシピに保存しました')),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
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
