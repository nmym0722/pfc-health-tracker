import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recipe.dart';
import '../../models/meal_record.dart';
import '../../models/food_master.dart';
import '../../providers/food_master_provider.dart';
import '../../providers/meal_provider.dart';
import '../common/food_edit_dialog.dart';
import '../common/recipe_edit_dialog.dart';
import '../profile/profile_settings_screen.dart';

class MyRecipesScreen extends ConsumerStatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  ConsumerState<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends ConsumerState<MyRecipesScreen> {
  String _libSearchQuery = '';
  String _libCategory = 'すべて';
  bool _isCategoryExpanded = false;

  static const _categories = [
    'すべて',
    '肉類',
    '加工肉',
    '魚介類',
    '卵・大豆類',
    '主食・穀物',
    '野菜類',
    'きのこ・海藻',
    '果物',
    '乳製品・サプリ',
    '油脂・調味料',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodMasters = ref.watch(foodMasterProvider);
    final recipes = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイレシピ & 食材マスタ'),
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(icon: const Icon(Icons.menu_book), text: '保存済みレシピ (${recipes.length})'),
                Tab(icon: const Icon(Icons.inventory_2), text: '食材ライブラリ (${foodMasters.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 1. 保存済みマイレシピ一覧
                  _buildRecipesTab(context, theme, recipes),

                  // 2. 食材ライブラリ一覧 (カテゴリ・検索対応)
                  _buildFoodLibraryTab(theme, foodMasters),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. マイレシピタブ
  Widget _buildRecipesTab(
    BuildContext context,
    ThemeData theme,
    List<Recipe> recipes,
  ) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'マイレシピはまだありません',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '「食事入力」タブの「食材合算」から\n複数の食材を組み合わせてマイレシピとして保存できます。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.soup_kitchen, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              recipe.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'マイレシピを編集',
                      color: theme.colorScheme.primary,
                      onPressed: () async {
                        final edited = await RecipeEditDialog.show(context, recipe: recipe);
                        if (edited != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('「${edited.name}」を更新しました')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      onPressed: () => _confirmDeleteRecipe(context, recipe),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('1人前カロリー', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${recipe.caloriesPerServing.round()} kcal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('P: タンパク質', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${recipe.proteinPerServing.toStringAsFixed(1)} g',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('F: 脂質', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${recipe.fatPerServing.toStringAsFixed(1)} g',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.tertiary),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('C: 炭水化物', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${recipe.carbsPerServing.toStringAsFixed(1)} g',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '使用食材 (${recipe.ingredients.length}品 / ${recipe.servings}人前分量):',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: recipe.ingredients.map((ing) {
                    return Chip(
                      label: Text(
                        '${ing.food.name} ${ing.amount.round()}${ing.food.unitLabel}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showAddMealBottomSheet(context, recipe),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('今日の食事に記録する'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. 食材ライブラリ一覧 (検索 & カテゴリフィルター対応)
  Widget _buildFoodLibraryTab(ThemeData theme, List<FoodMaster> foodMasters) {
    final filtered = foodMasters.where((food) {
      final matchesSearch = _libSearchQuery.isEmpty ||
          food.name.contains(_libSearchQuery) ||
          (food.category?.contains(_libSearchQuery) ?? false);
      final matchesCategory = _libCategory == 'すべて' ||
          food.category == _libCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: '食材ライブラリを検索 (例: 鮭, 卵, 醤油)',
                  leading: const Icon(Icons.search),
                  onChanged: (val) {
                    setState(() {
                      _libSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openFoodDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('食材追加'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isCategoryExpanded
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _categories.map((cat) {
                            final isSelected = _libCategory == cat;
                            return FilterChip(
                              label: Text(cat, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() {
                                  _libCategory = cat;
                                });
                              },
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      )
                    : SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _libCategory == cat;
                            return FilterChip(
                              label: Text(cat, style: const TextStyle(fontSize: 12)),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() {
                                  _libCategory = cat;
                                });
                              },
                              visualDensity: VisualDensity.compact,
                            );
                          },
                        ),
                      ),
              ),
              IconButton(
                icon: Icon(
                  _isCategoryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 22,
                ),
                tooltip: _isCategoryExpanded ? '1行に折りたたむ' : 'すべてのカテゴリを展開',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    _isCategoryExpanded = !_isCategoryExpanded;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final food = filtered[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 20),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (food.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'カスタム',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  '${food.baseAmountLabel}あたり: ${food.calories}kcal\nP:${food.protein}g / F:${food.fat}g / C:${food.carbs}g',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        food.isFavorite ? Icons.star : Icons.star_border,
                        color: food.isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      tooltip: food.isFavorite ? 'お気に入り解除' : 'お気に入り登録',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        ref.read(foodMasterProvider.notifier).toggleFavorite(food.id);
                      },
                    ),
                    if (food.category != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Chip(
                          label: Text(food.category!, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'カロリー・PFCを調整',
                      onPressed: () => _openFoodDialog(food: food),
                    ),
                  ],
                ),
                onTap: () => _openFoodDialog(food: food),
              );
            },
          ),
        ),
      ],
    );
  }

  // 食材追加 / 調整ダイアログ
  Future<void> _openFoodDialog({FoodMaster? food}) async {
    final saved = await FoodEditDialog.show(context, food: food);
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            food != null
                ? '「${saved.name}」の栄養価を更新しました'
                : '「${saved.name}」をライブラリに追加しました',
          ),
        ),
      );
    }
  }

  // レシピ削除の確認ダイアログ
  void _confirmDeleteRecipe(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('マイレシピの削除'),
          content: Text('「${recipe.name}」を削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(recipeProvider.notifier).removeRecipe(recipe.id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「${recipe.name}」を削除しました')),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // 食事記録に追加するボトムシート
  void _showAddMealBottomSheet(BuildContext context, Recipe recipe) {
    MealType selectedMealType = MealType.lunch;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '「${recipe.name}」を記録',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1人前: ${recipe.caloriesPerServing.round()} kcal (P:${recipe.proteinPerServing.toStringAsFixed(1)}g F:${recipe.fatPerServing.toStringAsFixed(1)}g C:${recipe.carbsPerServing.toStringAsFixed(1)}g)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('食事区分を選択:'),
                  const SizedBox(height: 10),
                  SegmentedButton<MealType>(
                    segments: MealType.values.map((type) {
                      return ButtonSegment<MealType>(
                        value: type,
                        label: Text(type.label),
                      );
                    }).toList(),
                    selected: {selectedMealType},
                    onSelectionChanged: (newSelection) {
                      setSheetState(() {
                        selectedMealType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final mealItems = recipe.ingredients.map((ing) {
                        final perServingAmount = ing.amount / recipe.servings;
                        final ratio = perServingAmount / ing.food.baseAmount;

                        return MealItem(
                          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${ing.food.id}',
                          name: '${ing.food.name} (${recipe.name})',
                          foodId: ing.food.id,
                          amount: perServingAmount,
                          unit: ing.food.unitLabel,
                          calories: ing.food.calories * ratio,
                          protein: ing.food.protein * ratio,
                          fat: ing.food.fat * ratio,
                          carbs: ing.food.carbs * ratio,
                        );
                      }).toList();

                      ref.read(mealProvider.notifier).addMealItems(
                        date: DateTime.now(),
                        type: selectedMealType,
                        items: mealItems,
                      );

                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('「${recipe.name}」を${selectedMealType.label}に記録しました')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('食事に記録する'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
