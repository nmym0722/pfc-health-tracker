import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/recipe.dart';
import '../../models/meal_record.dart';
import '../../models/food_master.dart';
import '../../core/utils/amount_parser.dart';
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
  String? _selectedRecipeGroup;

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
    final allGroups = ref.watch(recipeGroupsProvider);
    final sortType = ref.watch(recipeSortTypeProvider);

    // グループによる絞り込み
    final filteredRecipes = _selectedRecipeGroup == null
        ? List<Recipe>.from(recipes)
        : recipes.where((r) => r.effectiveGroup == _selectedRecipeGroup).toList();

    // ソート順の適用
    final sortedRecipes = List<Recipe>.from(filteredRecipes);
    switch (sortType) {
      case RecipeSortType.custom:
        break;
      case RecipeSortType.nameAsc:
        sortedRecipes.sort((a, b) => a.name.compareTo(b.name));
        break;
      case RecipeSortType.createdAtDesc:
        sortedRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case RecipeSortType.createdAtAsc:
        sortedRecipes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case RecipeSortType.caloriesDesc:
        sortedRecipes.sort((a, b) => b.caloriesPerServing.compareTo(a.caloriesPerServing));
        break;
      case RecipeSortType.proteinDesc:
        sortedRecipes.sort((a, b) => b.proteinPerServing.compareTo(a.proteinPerServing));
        break;
    }

    final isCustomReorderable = sortType == RecipeSortType.custom && _selectedRecipeGroup == null;

    return Column(
      children: [
        // グループ絞り込みチップ & 並べ替えメニュー
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 4.0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: Text('すべて (${recipes.length})'),
                        selected: _selectedRecipeGroup == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedRecipeGroup = null);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ...allGroups.map((group) {
                        final count = recipes.where((r) => r.effectiveGroup == group).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('$group ($count)'),
                            selected: _selectedRecipeGroup == group,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRecipeGroup = selected ? group : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<RecipeSortType>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      sortType.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                tooltip: '並べ替え順を変更',
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (newSort) {
                  ref.read(recipeSortTypeProvider.notifier).state = newSort;
                },
                itemBuilder: (context) => RecipeSortType.values.map((st) {
                  final isSelected = st == sortType;
                  return PopupMenuItem(
                    value: st,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          st.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: sortedRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 56, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        _selectedRecipeGroup == null
                            ? 'マイレシピはまだありません'
                            : '「$_selectedRecipeGroup」のマイレシピはありません',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '「食事入力」タブの「食材合算」や「直接入力」から\nマイレシピとして保存できます。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : (isCustomReorderable
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedRecipes.length,
                      onReorder: (oldIndex, newIndex) {
                        ref.read(recipeProvider.notifier).reorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final recipe = sortedRecipes[index];
                        return _buildRecipeCard(
                          context,
                          theme,
                          recipe,
                          key: ValueKey(recipe.id),
                          showDragHandle: true,
                          index: index,
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = sortedRecipes[index];
                        return _buildRecipeCard(
                          context,
                          theme,
                          recipe,
                          key: ValueKey(recipe.id),
                          showDragHandle: false,
                          index: index,
                        );
                      },
                    )),
        ),
      ],
    );
  }

  /// マイレシピ一覧詳細カード
  Widget _buildRecipeCard(
    BuildContext context,
    ThemeData theme,
    Recipe recipe, {
    required Key key,
    required bool showDragHandle,
    required int index,
  }) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDragHandle)
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                      child: Icon(Icons.drag_handle, color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.soup_kitchen, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe.effectiveGroup,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
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

  // 食事記録に追加するボトムシート（分量・倍率指定対応）
  void _showAddMealBottomSheet(BuildContext context, Recipe recipe) {
    MealType selectedMealType = MealType.lunch;
    double currentScale = 1.0;
    final scaleController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final scaledCal = recipe.caloriesPerServing * currentScale;
            final scaledP = recipe.proteinPerServing * currentScale;
            final scaledF = recipe.fatPerServing * currentScale;
            final scaledC = recipe.carbsPerServing * currentScale;

            void setScale(double newScale) {
              if (newScale <= 0.05 || newScale > 50.0) return;
              final rounded = (newScale * 100).round() / 100.0;
              setSheetState(() {
                currentScale = rounded;
                scaleController.text = AmountParser.formatAmount(rounded);
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 24.0,
                left: 24.0,
                right: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
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
                    '計算値: ${scaledCal.round()} kcal (P:${scaledP.toStringAsFixed(1)}g F:${scaledF.toStringAsFixed(1)}g C:${scaledC.toStringAsFixed(1)}g)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => setScale(currentScale - 0.1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('-0.1', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: scaleController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: '分量 (人前・倍)',
                            suffixText: '人前',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final parsed = AmountParser.parse(val);
                            if (parsed != null && parsed > 0) {
                              setSheetState(() {
                                currentScale = parsed;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => setScale(currentScale + 0.1),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('+0.1', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      {'label': '1/2 (0.5)', 'scale': 0.5},
                      {'label': '0.8', 'scale': 0.8},
                      {'label': '1 (標準)', 'scale': 1.0},
                      {'label': '1.5', 'scale': 1.5},
                      {'label': '2', 'scale': 2.0},
                    ].map((p) {
                      final s = p['scale'] as double;
                      return ChoiceChip(
                        label: Text(p['label'] as String, style: const TextStyle(fontSize: 12)),
                        selected: (currentScale - s).abs() < 0.02,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) => setScale(s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('食事区分を選択:'),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      final batchId = 'recipe-${DateTime.now().millisecondsSinceEpoch}-${recipe.id}';
                      final scaleText = (currentScale - 1.0).abs() < 0.01
                          ? ''
                          : ' ×${AmountParser.formatAmount(currentScale)}';
                      final recipeDisplayName = '${recipe.name}$scaleText';

                      final mealItems = recipe.ingredients.map((ing) {
                        final perServingAmount = (ing.amount / recipe.servings) * currentScale;
                        final ratio = perServingAmount / ing.food.baseAmount;

                        return MealItem(
                          id: 'item-${DateTime.now().millisecondsSinceEpoch}-${ing.food.id}',
                          name: '${ing.food.name} ($recipeDisplayName)',
                          foodId: ing.food.id,
                          recipeId: batchId,
                          recipeName: recipeDisplayName,
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
                        SnackBar(content: Text('「$recipeDisplayName」を${selectedMealType.label}に記録しました')),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text('この分量で記録する (${scaledCal.round()} kcal)'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
