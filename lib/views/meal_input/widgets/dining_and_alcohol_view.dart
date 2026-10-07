import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/dining_preset.dart';
import '../../../models/food_master.dart';
import '../../../models/meal_record.dart';
import '../../../models/recipe.dart';
import '../../../providers/food_master_provider.dart';
import '../../../providers/meal_provider.dart';

/// 外食プリセット（3段階油加減）およびアルコール専用クイックカウンターのタブ画面
class DiningAndAlcoholView extends ConsumerStatefulWidget {
  final MealType initialMealType;
  final DateTime? targetDate;
  final void Function(String message)? onSaved;

  const DiningAndAlcoholView({
    super.key,
    required this.initialMealType,
    this.targetDate,
    this.onSaved,
  });

  @override
  ConsumerState<DiningAndAlcoholView> createState() => _DiningAndAlcoholViewState();
}

class _DiningAndAlcoholViewState extends ConsumerState<DiningAndAlcoholView> {
  late MealType _selectedMealType;

  // 外食プリセット用ステート
  DiningPreset? _selectedPreset;
  OilIntensity _selectedIntensity = OilIntensity.regular;

  // アルコールクイックカウンター用ステート (presetId -> 杯数)
  final Map<String, int> _alcoholCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType;
    // デフォルトで最初の外食プリセットを選択
    if (DiningPreset.defaultPresets.isNotEmpty) {
      _selectedPreset = DiningPreset.defaultPresets.first;
    }
  }

  int _getAlcoholCount(String id) => _alcoholCounts[id] ?? 0;

  void _updateAlcoholCount(String id, int delta) {
    setState(() {
      final current = _alcoholCounts[id] ?? 0;
      final next = (current + delta).clamp(0, 99);
      if (next == 0) {
        _alcoholCounts.remove(id);
      } else {
        _alcoholCounts[id] = next;
      }
    });
  }

  void _clearAlcoholCounts() {
    setState(() {
      _alcoholCounts.clear();
    });
  }

  // アルコールの合計計算
  ({double calories, double alcoholGrams, double carbsGrams, int totalDrinks}) _calculateAlcoholTotals() {
    double totalCalories = 0.0;
    double totalAlcohol = 0.0;
    double totalCarbs = 0.0;
    int drinks = 0;

    for (final preset in AlcoholPreset.defaultList) {
      final count = _getAlcoholCount(preset.id);
      if (count > 0) {
        drinks += count;
        totalCalories += preset.calories * count;
        totalAlcohol += preset.alcoholGrams * count;
        totalCarbs += preset.carbsGrams * count;
      }
    }

    return (
      calories: totalCalories,
      alcoholGrams: totalAlcohol,
      carbsGrams: totalCarbs,
      totalDrinks: drinks,
    );
  }

  DateTime get _effectiveDate =>
      widget.targetDate ?? ref.read(selectedDateProvider);

  /// 外食プリセットを食事記録に保存
  void _savePresetMeal() {
    final preset = _selectedPreset;
    if (preset == null) return;

    final n = preset.calculateNutrition(_selectedIntensity);
    final intensityLabel = _selectedIntensity == OilIntensity.regular
        ? ''
        : '（${_selectedIntensity.label}）';
    final itemName = '${preset.name}$intensityLabel';

    final item = MealItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      name: itemName,
      amount: 1.0,
      unit: '人前',
      calories: n.calories,
      protein: n.protein,
      fat: n.fat,
      carbs: n.carbs,
    );

    ref.read(mealProvider.notifier).addMealItem(
      date: _effectiveDate,
      type: _selectedMealType,
      item: item,
    );

    final msg = '${_selectedMealType.label}に「$itemName」（${n.calories.round()} kcal）を記録しました！';
    if (widget.onSaved != null) {
      widget.onSaved!(msg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// 外食プリセットをマイリスト（外食メニュー）に保存
  void _savePresetToMyList() {
    final preset = _selectedPreset;
    if (preset == null) return;

    final n = preset.calculateNutrition(_selectedIntensity);
    final intensityLabel = _selectedIntensity == OilIntensity.regular
        ? ''
        : '（${_selectedIntensity.label}）';
    final name = '${preset.name}$intensityLabel';

    final food = FoodMaster(
      id: 'food-preset-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      baseAmount: 1.0,
      unit: FoodUnit.serving,
      calories: n.calories,
      protein: n.protein,
      fat: n.fat,
      carbs: n.carbs,
      category: '外食',
      isCustom: true,
    );

    final recipe = Recipe(
      id: 'recipe-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: '外食プリセットより保存 (${preset.category})',
      servings: 1,
      category: MyListCategory.diningOut,
      ingredients: [
        RecipeIngredient(food: food, amount: 1.0),
      ],
      createdAt: DateTime.now(),
    );

    ref.read(recipeProvider.notifier).addRecipe(recipe);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$name」を外食マイリストに保存しました！')),
    );
  }

  /// 合算したアルコールを食事記録に保存
  void _saveAlcoholMeal() {
    final totals = _calculateAlcoholTotals();
    if (totals.totalDrinks == 0) return;

    // 内訳を食品名にまとめる (例: 生ビールx2, ハイボールx1)
    final breakdown = <String>[];
    for (final preset in AlcoholPreset.defaultList) {
      final count = _getAlcoholCount(preset.id);
      if (count > 0) {
        breakdown.add('${preset.name}x$count');
      }
    }
    final name = 'お酒（${breakdown.join(', ')}）';

    final item = MealItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      amount: totals.totalDrinks.toDouble(),
      unit: '杯',
      calories: totals.calories,
      protein: 0.0,
      fat: 0.0,
      carbs: totals.carbsGrams,
    );

    ref.read(mealProvider.notifier).addMealItem(
      date: _effectiveDate,
      type: _selectedMealType,
      item: item,
    );

    _clearAlcoholCounts();

    final msg = '${_selectedMealType.label}に「$name」（${totals.calories.round()} kcal）を記録しました！';
    if (widget.onSaved != null) {
      widget.onSaved!(msg);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alcTotals = _calculateAlcoholTotals();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 食事区分セレクター (朝/昼/夕/間食)
          SegmentedButton<MealType>(
            segments: MealType.values.map((type) {
              return ButtonSegment<MealType>(
                value: type,
                label: Text(type.label),
              );
            }).toList(),
            selected: {_selectedMealType},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedMealType = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 20),

          // ===================================================================
          // セクション 1: 外食プリセット & 3段階スライダートグル
          // ===================================================================
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        '外食・会食プリセット',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '定番メニューを選び、油加減（脂質）をタップで即時補正できます。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // メニュー選択ドロップダウン
                  DropdownButtonFormField<DiningPreset>(
                    value: _selectedPreset,
                    decoration: InputDecoration(
                      labelText: 'メニューを選択',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: DiningPreset.defaultPresets.map((preset) {
                      return DropdownMenuItem<DiningPreset>(
                        value: preset,
                        child: Text(
                          '${preset.name} (${preset.category})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPreset = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3段階 油加減セグメントボタン
                  Text(
                    '油加減・ボリューム（脂質調整）',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<OilIntensity>(
                      segments: OilIntensity.values.map((intensity) {
                        return ButtonSegment<OilIntensity>(
                          value: intensity,
                          label: Text(intensity.label),
                          tooltip: intensity.description,
                        );
                      }).toList(),
                      selected: {_selectedIntensity},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedIntensity = newSelection.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _selectedIntensity.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 調整後栄養価プレビュー
                  if (_selectedPreset != null) ...[
                    _buildNutritionPreviewCard(
                      theme,
                      _selectedPreset!.calculateNutrition(_selectedIntensity),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _savePresetToMyList,
                          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                          label: const Text('マイリスト保存'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _savePresetMeal,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              '${_selectedPreset!.name} を記録 (${_selectedPreset!.calculateNutrition(_selectedIntensity).calories.round()} kcal)',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ===================================================================
          // セクション 2: アルコール専用クイックカウンター
          // ===================================================================
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_bar, color: theme.colorScheme.secondary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'お酒クイックカウンター',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (alcTotals.totalDrinks > 0)
                        TextButton(
                          onPressed: _clearAlcoholCounts,
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text('リセット'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '杯数をタップするだけで、アルコール熱量（7kcal/g）と糖質を瞬時に合算します。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 合算サマリーバナー
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alcTotals.totalDrinks > 0
                          ? theme.colorScheme.secondaryContainer.withOpacity(0.5)
                          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: alcTotals.totalDrinks > 0
                            ? theme.colorScheme.secondary.withOpacity(0.4)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          theme,
                          label: '合計杯数',
                          value: '${alcTotals.totalDrinks} 杯',
                          color: theme.colorScheme.onSurface,
                        ),
                        _buildSummaryItem(
                          theme,
                          label: '純アルコール',
                          value: '${alcTotals.alcoholGrams.toStringAsFixed(1)} g',
                          color: theme.colorScheme.secondary,
                        ),
                        _buildSummaryItem(
                          theme,
                          label: '糖質',
                          value: '${alcTotals.carbsGrams.toStringAsFixed(1)} g',
                          color: theme.colorScheme.primary,
                        ),
                        _buildSummaryItem(
                          theme,
                          label: '総エネルギー',
                          value: '${alcTotals.calories.round()} kcal',
                          color: theme.colorScheme.error,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // お酒リスト (杯数カウンター)
                  ...AlcoholPreset.defaultList.map((alc) {
                    final count = _getAlcoholCount(alc.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? theme.colorScheme.surfaceContainerHigh
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: count > 0
                                ? theme.colorScheme.secondary.withOpacity(0.5)
                                : theme.colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alc.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${alc.servingLabel} ・ ${alc.calories.round()}kcal (糖質${alc.carbsGrams}g)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // マイナス / カウント / プラス ボタン
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 22),
                              color: count > 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.outlineVariant,
                              onPressed: count > 0 ? () => _updateAlcoholCount(alc.id, -1) : null,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 28),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: count > 0 ? theme.colorScheme.primary : theme.colorScheme.outline,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, size: 22),
                              color: theme.colorScheme.primary,
                              onPressed: () => _updateAlcoholCount(alc.id, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  FilledButton.tonalIcon(
                    onPressed: alcTotals.totalDrinks > 0 ? _saveAlcoholMeal : null,
                    icon: const Icon(Icons.local_bar, size: 18),
                    label: Text(
                      alcTotals.totalDrinks > 0
                          ? 'お酒（${alcTotals.totalDrinks}杯・${alcTotals.calories.round()} kcal）を記録'
                          : '杯数を選んで記録',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 調整後PFCのプレビューカード
  Widget _buildNutritionPreviewCard(
    ThemeData theme,
    ({double calories, double protein, double fat, double carbs}) n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            theme,
            label: 'エネルギー',
            value: '${n.calories.round()} kcal',
            color: theme.colorScheme.primary,
            isBold: true,
          ),
          _buildSummaryItem(
            theme,
            label: 'たんぱく質',
            value: '${n.protein.toStringAsFixed(1)} g',
            color: const Color(0xFF2E7D32),
          ),
          _buildSummaryItem(
            theme,
            label: '脂質',
            value: '${n.fat.toStringAsFixed(1)} g',
            color: const Color(0xFFC62828),
          ),
          _buildSummaryItem(
            theme,
            label: '炭水化物',
            value: '${n.carbs.toStringAsFixed(1)} g',
            color: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 14 : 12,
          ),
        ),
      ],
    );
  }
}
