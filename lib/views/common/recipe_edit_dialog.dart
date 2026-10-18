import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/amount_parser.dart';
import '../../models/food_master.dart';
import '../../models/recipe.dart';
import '../../providers/food_master_provider.dart';

class RecipeEditDialog extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeEditDialog({
    super.key,
    required this.recipe,
  });

  static Future<Recipe?> show(BuildContext context, {required Recipe recipe}) {
    return showDialog<Recipe>(
      context: context,
      builder: (ctx) => RecipeEditDialog(recipe: recipe),
    );
  }

  @override
  ConsumerState<RecipeEditDialog> createState() => _RecipeEditDialogState();
}

class _RecipeEditDialogState extends ConsumerState<RecipeEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late int _servings;
  late MyListCategory _category;
  late List<RecipeIngredient> _ingredients;
  late List<TextEditingController> _amountControllers;

  FoodMaster? _selectedFoodToAdd;
  final _newFoodAmountController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _descController = TextEditingController(text: widget.recipe.description ?? '');
    _servings = widget.recipe.servings > 0 ? widget.recipe.servings : 1;
    _category = widget.recipe.category;
    _ingredients = List<RecipeIngredient>.from(widget.recipe.ingredients);
    _amountControllers = _ingredients
        .map((ing) => TextEditingController(text: AmountParser.formatAmount(ing.amount)))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _amountControllers) {
      c.dispose();
    }
    _newFoodAmountController.dispose();
    super.dispose();
  }

  void _syncAmountAt(int index, String value) {
    final parsed = AmountParser.parse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        _ingredients[index] = _ingredients[index].copyWith(amount: parsed);
      });
    }
  }

  void _removeIngredientAt(int index) {
    if (_ingredients.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最低1つの食材が必要です')),
      );
      return;
    }
    setState(() {
      _ingredients.removeAt(index);
      final removedCtrl = _amountControllers.removeAt(index);
      removedCtrl.dispose();
    });
  }

  void _addIngredient() {
    if (_selectedFoodToAdd == null) return;
    final parsed = AmountParser.parse(_newFoodAmountController.text);
    if (parsed == null || parsed <= 0) return;

    setState(() {
      final newIng = RecipeIngredient(food: _selectedFoodToAdd!, amount: parsed);
      _ingredients.add(newIng);
      _amountControllers.add(
        TextEditingController(text: AmountParser.formatAmount(parsed)),
      );
      _selectedFoodToAdd = null;
      _newFoodAmountController.text = '100';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFoods = ref.watch(foodMasterProvider);

    final totalCal = _ingredients.fold(0.0, (s, i) => s + i.calories);
    final totalP = _ingredients.fold(0.0, (s, i) => s + i.protein);
    final totalF = _ingredients.fold(0.0, (s, i) => s + i.fat);
    final totalC = _ingredients.fold(0.0, (s, i) => s + i.carbs);

    final perCal = totalCal / _servings;
    final perP = totalP / _servings;
    final perF = totalF / _servings;
    final perC = totalC / _servings;

    return AlertDialog(
      title: const Text('マイレシピの編集'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'レシピ・メニュー名 *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'メモ・説明 (任意)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<MyListCategory>(
                segments: MyListCategory.values.map((cat) {
                  return ButtonSegment<MyListCategory>(
                    value: cat,
                    label: Text(cat.shortLabel, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                selected: {_category},
                onSelectionChanged: (newSel) {
                  setState(() {
                    _category = newSel.first;
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('何人前分:', style: TextStyle(fontSize: 13)),
                  DropdownButton<int>(
                    value: _servings,
                    items: [1, 2, 3, 4, 5, 6].map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text('$s 人前'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _servings = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              const Divider(height: 16),
              Text(
                '使用食材・分量 (${_ingredients.length}品)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(_ingredients.length, (index) {
                final ing = _ingredients[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.food.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${ing.calories.round()}kcal (P:${ing.protein.toStringAsFixed(1)} F:${ing.fat.toStringAsFixed(1)} C:${ing.carbs.toStringAsFixed(1)})',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 95,
                        child: TextField(
                          controller: _amountControllers[index],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            suffixText: ing.food.unitLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (val) => _syncAmountAt(index, val),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, size: 18, color: theme.colorScheme.error),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeIngredientAt(index),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              // 食材を追加するミニ行
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<FoodMaster>(
                      value: _selectedFoodToAdd,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '食材を追加 (任意)',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: allFoods.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(
                            '${f.name} (${f.baseAmountLabel}:${f.calories.round()}kcal)',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (food) {
                        setState(() {
                          _selectedFoodToAdd = food;
                          if (food != null) {
                            _newFoodAmountController.text =
                                AmountParser.formatAmount(food.baseAmount);
                          }
                        });
                      },
                    ),
                    if (_selectedFoodToAdd != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newFoodAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: '分量 (${_selectedFoodToAdd!.unitLabel})',
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: _addIngredient,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('追加'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1人前あたり: ${perCal.round()} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'P:${perP.toStringAsFixed(1)}g / F:${perF.toStringAsFixed(1)}g / C:${perC.toStringAsFixed(1)}g',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty || _ingredients.isEmpty) return;

            final updated = widget.recipe.copyWith(
              name: name,
              description: _descController.text.trim().isEmpty
                  ? null
                  : _descController.text.trim(),
              clearDescription: _descController.text.trim().isEmpty,
              servings: _servings,
              category: _category,
              ingredients: _ingredients,
            );
            ref.read(recipeProvider.notifier).updateRecipe(updated);
            Navigator.of(context).pop(updated);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
