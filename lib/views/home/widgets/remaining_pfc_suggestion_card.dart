import 'package:flutter/material.dart';
import '../../../core/algorithms/remaining_pfc_advisor.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../models/food_master.dart';
import '../../../models/meal_record.dart';
import '../../../models/recipe.dart';

class RemainingPfcSuggestionCard extends StatefulWidget {
  final double targetCalories;
  final double currentCalories;
  final double targetProtein;
  final double currentProtein;
  final double targetFat;
  final double currentFat;
  final double targetCarbs;
  final double currentCarbs;
  final List<FoodMaster> foods;
  final List<Recipe> recipes;
  final MealType defaultMealType;
  final void Function(SuggestedFoodPortion portion, MealType mealType) onAddSuggestedFood;
  final void Function(Recipe recipe, MealType mealType) onAddSuggestedRecipe;

  const RemainingPfcSuggestionCard({
    super.key,
    required this.targetCalories,
    required this.currentCalories,
    required this.targetProtein,
    required this.currentProtein,
    required this.targetFat,
    required this.currentFat,
    required this.targetCarbs,
    required this.currentCarbs,
    required this.foods,
    required this.recipes,
    required this.defaultMealType,
    required this.onAddSuggestedFood,
    required this.onAddSuggestedRecipe,
  });

  @override
  State<RemainingPfcSuggestionCard> createState() => _RemainingPfcSuggestionCardState();
}

class _RemainingPfcSuggestionCardState extends State<RemainingPfcSuggestionCard> {
  bool _isExpanded = false;
  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.defaultMealType;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advice = RemainingPfcAdvisor.analyze(
      targetCalories: widget.targetCalories,
      currentCalories: widget.currentCalories,
      targetProtein: widget.targetProtein,
      currentProtein: widget.currentProtein,
      targetFat: widget.targetFat,
      currentFat: widget.currentFat,
      targetCarbs: widget.targetCarbs,
      currentCarbs: widget.currentCarbs,
      foods: widget.foods,
      recipes: widget.recipes,
    );

    if (advice.suggestedFoods.isEmpty && advice.matchingRecipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '残りPFC逆算アシスト（あと何を食べる？）',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          advice.headline,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: _isExpanded ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 追加先の食事区分セレクター
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ワンタップ追加先:',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SegmentedButton<MealType>(
                        segments: MealType.values.map((t) {
                          return ButtonSegment<MealType>(
                            value: t,
                            label: Text(t.label, style: const TextStyle(fontSize: 11)),
                          );
                        }).toList(),
                        selected: {_selectedMealType},
                        onSelectionChanged: (sel) {
                          setState(() {
                            _selectedMealType = sel.first;
                          });
                        },
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 逆算された食材リスト
                  ...advice.suggestedFoods.map((portion) {
                    final amtStr =
                        '${AmountParser.formatAmount(portion.recommendedAmount)}${portion.food.unitLabel}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        portion.reasonTag,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${portion.food.name} ($amtStr)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${portion.calories.round()}kcal | P:${portion.protein.toStringAsFixed(1)}g F:${portion.fat.toStringAsFixed(1)}g C:${portion.carbs.toStringAsFixed(1)}g',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => widget.onAddSuggestedFood(portion, _selectedMealType),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('追加', style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // 条件に合うマイレシピがある場合の提案
                  if (advice.matchingRecipes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '残り枠に収まるマイリスト:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...advice.matchingRecipes.map((recipe) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${recipe.caloriesPerServing.round()}kcal (P:${recipe.proteinPerServing.toStringAsFixed(1)}g F:${recipe.fatPerServing.toStringAsFixed(1)}g C:${recipe.carbsPerServing.toStringAsFixed(1)}g)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => widget.onAddSuggestedRecipe(recipe, _selectedMealType),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('追加', style: TextStyle(fontSize: 12)),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
