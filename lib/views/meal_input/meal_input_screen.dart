import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/meal_record.dart';
import '../../models/food_master.dart';
import '../../models/recipe.dart';
import '../../core/utils/amount_parser.dart';
import '../../providers/meal_provider.dart';
import '../../providers/food_master_provider.dart';
import '../common/food_edit_dialog.dart';
import '../main_navigation_screen.dart';
import 'camera_capture_view.dart';
import 'widgets/dining_and_alcohol_view.dart';

class MealInputScreen extends ConsumerStatefulWidget {
  final MealType initialMealType;
  final DateTime? targetDate;
  final bool isModal;

  const MealInputScreen({
    super.key,
    required this.initialMealType,
    this.targetDate,
    this.isModal = false,
  });

  @override
  ConsumerState<MealInputScreen> createState() => _MealInputScreenState();
}

class _MealInputScreenState extends ConsumerState<MealInputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late MealType _selectedMealType;

  // 1. 直接入力用コントローラー
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  // 2. 食材合算（調理ボウル）用ステート
  final List<RecipeIngredient> _bowlIngredients = [];
  String _searchQuery = '';
  FoodMaster? _selectedFoodForBowl;
  final _bowlAmountController = TextEditingController(text: '100');

  // 3. マイリスト用ステート (カテゴリ絞り込み & 分量割合)
  MyListCategory? _selectedMyListCategory; // null = すべて
  final Map<String, double> _recipeScaleMap = {};

  static const _foodCategories = [
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _selectedMealType = widget.initialMealType;
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 栄養成分表示の写真撮影・画像選択シートを表示
  Future<void> _openCameraCapture() async {
    final result = await NutritionPhotoPickerSheet.show(context);

    if (result == null || !mounted) return;

    // メニュー・食品名は空欄のままにする
    _nameController.text = '';

    // 数値フォーマット（整数なら小数を省く）
    String formatNum(double val) {
      if (val == val.roundToDouble()) {
        return val.toInt().toString();
      }
      return val.toStringAsFixed(1);
    }

    _caloriesController.text = formatNum(result.effectiveCalories);
    _proteinController.text = formatNum(result.effectiveProtein);
    _fatController.text = formatNum(result.effectiveFat);
    _carbsController.text = formatNum(result.effectiveCarbs);

    final unitText =
        result.servingUnit != null ? '（${result.servingUnit}）' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('パッケージの栄養成分表示$unitTextを反映しました！'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _bowlAmountController.dispose();
    super.dispose();
  }

  // ボウル内の合計値
  double get _bowlCalories =>
      _bowlIngredients.fold(0.0, (sum, item) => sum + item.calories);
  double get _bowlProtein =>
      _bowlIngredients.fold(0.0, (sum, item) => sum + item.protein);
  double get _bowlFat =>
      _bowlIngredients.fold(0.0, (sum, item) => sum + item.fat);
  double get _bowlCarbs =>
      _bowlIngredients.fold(0.0, (sum, item) => sum + item.carbs);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodMasters = ref.watch(foodMasterProvider);
    final recipes = ref.watch(recipeProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isModal,
        title: const Text('食事を入力'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_border), text: 'マイリスト'),
            Tab(icon: Icon(Icons.edit_note), text: '直接入力'),
            Tab(icon: Icon(Icons.restaurant), text: '外食・お酒'),
            Tab(icon: Icon(Icons.soup_kitchen), text: '食材合算'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. マイレシピ・マイリストから追加タブ
          _buildRecipePickerTab(theme, recipes),

          // 2. クイック直接入力タブ
          _buildDirectInputTab(theme),

          // 3. 外食プリセット & お酒クイックカウンタータブ
          DiningAndAlcoholView(
            initialMealType: _selectedMealType,
            targetDate: widget.targetDate,
            onSaved: _onMealSavedSuccess,
          ),

          // 4. 食材マスタ合算（自炊モード）タブ
          _buildCompositeCookingTab(theme, foodMasters),
        ],
      ),
      floatingActionButton: (_tabController.index == 3 && _selectedFoodForBowl == null)
          ? _buildBowlFloatingButton(theme)
          : null,
    );
  }

  // 右下フローティングボウルボタン（合算食材の内訳閲覧用）
  Widget _buildBowlFloatingButton(ThemeData theme) {
    final count = _bowlIngredients.length;
    final totalCal = _bowlCalories.round();

    return FloatingActionButton.extended(
      onPressed: () => _showBowlDetailsBottomSheet(theme),
      icon: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        backgroundColor: theme.colorScheme.error,
        child: const Icon(Icons.soup_kitchen, size: 24),
      ),
      label: Text(
        count > 0 ? 'ボウル ($totalCal kcal)' : 'ボウル (0品)',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: count > 0
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHigh,
      foregroundColor: count > 0
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  // 1. クイック直接入力フォーム
  Widget _buildDirectInputTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
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
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'メニュー・食品名',
              hintText: '例: プロテインバー, 外食の定食',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.camera_alt_outlined,
                  color: theme.colorScheme.primary,
                ),
                tooltip: '写真から栄養成分を自動入力',
                onPressed: _openCameraCapture,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'エネルギー (kcal)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'P: タンパク質 (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'F: 脂質 (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'C: 炭水化物 (g)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDirectInputAsRecipe,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('マイレシピに保存'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitDirectInput,
                  icon: const Icon(Icons.check),
                  label: const Text('食事記録に追加'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFoodCategoryIcon(String category) {
    switch (category) {
      case '肉類':
        return Icons.kebab_dining_outlined;
      case '加工肉':
        return Icons.lunch_dining_outlined;
      case '魚介類':
        return Icons.set_meal_outlined;
      case '卵・大豆類':
        return Icons.egg_outlined;
      case '主食・穀物':
        return Icons.rice_bowl_outlined;
      case '野菜類':
        return Icons.eco_outlined;
      case 'きのこ・海藻':
        return Icons.grass_outlined;
      case '果物':
        return Icons.apple_outlined;
      case '乳製品・サプリ':
        return Icons.local_drink_outlined;
      case '油脂・調味料':
        return Icons.water_drop_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  /// 食材リストタイル（星マークでお気に入りトグル可能、PFC調整は食材ライブラリに集約）
  Widget _buildFoodTile(ThemeData theme, FoodMaster food) {
    final isSelected = _selectedFoodForBowl?.id == food.id;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      title: Row(
        children: [
          Expanded(
            child: Text(
              food.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          if (food.isCustom)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
        '${food.baseAmountLabel}あたり: ${food.calories.round()}kcal (P:${food.protein}g F:${food.fat}g C:${food.carbs}g)',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              food.isFavorite ? Icons.star : Icons.star_border,
              size: 22,
              color: food.isFavorite ? Colors.amber : theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: food.isFavorite ? 'お気に入り解除' : 'お気に入りに登録',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              ref.read(foodMasterProvider.notifier).toggleFavorite(food.id);
            },
          ),
          Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            size: 22,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ],
      ),
      onTap: () {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() {
          _selectedFoodForBowl = food;
          _bowlAmountController.text = AmountParser.formatAmount(food.baseAmount);
        });
      },
    );
  }

  // 2. 自炊・食材合算計算タブ
  Widget _buildCompositeCookingTab(ThemeData theme, List<FoodMaster> allFoods) {
    final searchTrimmed = _searchQuery.trim().toLowerCase();
    final isSearching = searchTrimmed.isNotEmpty;

    final searchMatchedFoods = isSearching
        ? allFoods.where((f) {
            final nameMatch = f.name.toLowerCase().contains(searchTrimmed);
            final catMatch = f.category?.toLowerCase().contains(searchTrimmed) ?? false;
            return nameMatch || catMatch;
          }).toList()
        : <FoodMaster>[];

    final favoriteFoods = allFoods.where((f) => f.isFavorite).toList();

    return Column(
      children: [
        // 最上部タブのすぐ下に配置される食材検索バー & 新規食材追加ボタン
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 6.0),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: '食材を検索 (例: 鶏むね肉, 米, 卵)',
                  leading: const Icon(Icons.search),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _openAddFoodDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('食材追加'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ),

        // 食材欄：カテゴリ別のトグル開閉リスト（アコーディオン）または検索結果
        Expanded(
          child: isSearching
              ? (searchMatchedFoods.isEmpty
                  ? Center(
                      child: Text(
                        '「$_searchQuery」に一致する食材がありません',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchMatchedFoods.length,
                      itemBuilder: (context, index) {
                        return _buildFoodTile(theme, searchMatchedFoods[index]);
                      },
                    ))
              : ListView(
                  children: [
                    // 1. お気に入り食材トグル（最上部に配置）
                    if (favoriteFoods.isNotEmpty) ...[
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.amber.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(
                            'お気に入り食材',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${favoriteFoods.length}品',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          children: favoriteFoods
                              .map((food) => _buildFoodTile(theme, food))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // 2. 各カテゴリのトグル（アコーディオン）
                    ..._foodCategories.map((category) {
                      final categoryFoods =
                          allFoods.where((f) => f.category == category).toList();
                      if (categoryFoods.isEmpty) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            _getFoodCategoryIcon(category),
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${categoryFoods.length}品',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          children: categoryFoods
                              .map((food) => _buildFoodTile(theme, food))
                              .toList(),
                        ),
                      );
                    }),

                    // 3. その他 / カスタム食材
                    Builder(builder: (context) {
                      final otherFoods = allFoods
                          .where((f) =>
                              f.category == null ||
                              !_foodCategories.contains(f.category))
                          .toList();
                      if (otherFoods.isEmpty) return const SizedBox.shrink();

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.more_horiz,
                            color: theme.colorScheme.primary,
                          ),
                          title: const Text(
                            'その他 / カスタム',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${otherFoods.length}品',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          children: otherFoods
                              .map((food) => _buildFoodTile(theme, food))
                              .toList(),
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
        ),

        // 選択中食材の分量入力トレイ
        if (_selectedFoodForBowl != null) ...[
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFoodForBowl!.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _bowlAmountController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: '分量 (${_selectedFoodForBowl!.unitLabel})',
                          hintText: '例: 1/2, 2.5',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // クイック分量選択チップ (大さじ1/2, 小さじ1, 1/2個, 2.5個など)
                _buildQuickAmountChips(),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _addIngredientToBowl,
                  icon: const Icon(Icons.add),
                  label: const Text('ボウルに追加'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon(MyListCategory cat) {
    switch (cat) {
      case MyListCategory.ingredient:
        return Icons.egg_outlined;
      case MyListCategory.homeCooked:
        return Icons.soup_kitchen_outlined;
      case MyListCategory.diningOut:
        return Icons.storefront_outlined;
    }
  }

  // 1. マイレシピ・マイリストから追加タブ
  Widget _buildRecipePickerTab(ThemeData theme, List<Recipe> recipes) {
    // カテゴリによる絞り込み
    final filteredRecipes = _selectedMyListCategory == null
        ? recipes
        : recipes.where((r) => r.category == _selectedMyListCategory).toList();

    return Column(
      children: [
        // 食事区分セレクター (朝/昼/夕/間食)
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 6.0),
          child: SegmentedButton<MealType>(
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
        ),

        // マイリスト カテゴリ絞り込みフィルターチップ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('すべて (${recipes.length})'),
                  selected: _selectedMyListCategory == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMyListCategory = null);
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...MyListCategory.values.map((cat) {
                  final count = recipes.where((r) => r.category == cat).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      avatar: Icon(_getCategoryIcon(cat), size: 16),
                      label: Text('${cat.label} ($count)'),
                      selected: _selectedMyListCategory == cat,
                      onSelected: (selected) {
                        setState(() {
                          _selectedMyListCategory = selected ? cat : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: filteredRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border, size: 48, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        _selectedMyListCategory == null
                            ? '登録されたマイリストはありません'
                            : '「${_selectedMyListCategory!.label}」の登録はありません',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '「食材合算」や「直接入力」からマイリストに保存できます',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    final scale = _recipeScaleMap[recipe.id] ?? 1.0;
                    final isSingle = recipe.ingredients.length == 1;
                    final singleIng = isSingle ? recipe.ingredients.first : null;

                    // スケール適用後の栄養価
                    final cal = (recipe.caloriesPerServing * scale).round();
                    final p = (recipe.proteinPerServing * scale).toStringAsFixed(1);
                    final f = (recipe.fatPerServing * scale).toStringAsFixed(1);
                    final c = (recipe.carbsPerServing * scale).toStringAsFixed(1);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 上部ヘッダー（カテゴリバッジ、タイトル、削除ボタン）
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getCategoryIcon(recipe.category), size: 14, color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        recipe.category.shortLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    recipe.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  tooltip: 'マイリストから削除',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _confirmDeleteRecipe(recipe),
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
                            const SizedBox(height: 12),

                            // ===================================================
                            // 分量・割合（スケール）調整コントローラー
                            // ===================================================
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                isSingle
                                                    ? '分量: ${(singleIng!.amount * scale).round()}${singleIng.food.unitLabel} (${scale.toStringAsFixed(1)}倍)'
                                                    : '分量割合: ${scale.toStringAsFixed(1)}人前 (${(scale * 100).round()}%)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: theme.colorScheme.primary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: scale > 0.2
                                                ? () => setState(() => _recipeScaleMap[recipe.id] = ((scale - 0.1) * 10).round() / 10)
                                                : null,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${scale.toStringAsFixed(1)}x',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => setState(() => _recipeScaleMap[recipe.id] = ((scale + 0.1) * 10).round() / 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [0.5, 0.8, 1.0, 1.2, 1.5, 2.0].map((quickScale) {
                                      final isCur = (scale - quickScale).abs() < 0.05;
                                      return ChoiceChip(
                                        label: Text(
                                          '${quickScale}x',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isCur,
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        onSelected: (sel) {
                                          if (sel) setState(() => _recipeScaleMap[recipe.id] = quickScale);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 調整後栄養価（PFC・カロリー） & 食事に追加ボタン
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department, size: 18, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$cal kcal',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('P:${p}g ',
                                            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text('F:${f}g ',
                                            style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 11)),
                                        Text('C:${c}g',
                                            style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _submitRecipeToMeal(recipe, scale: scale),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('食事に追加'),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),

                            // 食材の内訳表示（自炊や複数食材時）
                            if (recipe.ingredients.isNotEmpty && !isSingle) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: recipe.ingredients.map((ing) {
                                  final scaledAmount = ((ing.amount / recipe.servings) * scale).round();
                                  return Chip(
                                    label: Text(
                                      '${ing.food.name} $scaledAmount${ing.food.unitLabel}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// マイレシピ削除の確認ダイアログ
  Future<void> _confirmDeleteRecipe(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('マイリストから削除'),
        content: Text('「${recipe.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(recipeProvider.notifier).removeRecipe(recipe.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${recipe.name}」を削除しました')),
      );
    }
  }

  // 調理ボウルの内訳詳細モーダルボトムシート
  void _showBowlDetailsBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.35,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // ドラッグハンドル
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // モーダルヘッダー
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.soup_kitchen, color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '調理ボウル (${_bowlIngredients.length}品)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_bowlIngredients.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  _bowlIngredients.clear();
                                });
                                setState(() {});
                              },
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('クリア'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: '閉じる',
                            onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 食材内訳リスト
                    Expanded(
                      child: _bowlIngredients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.soup_kitchen_outlined,
                                    size: 48,
                                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ボウルに食材が入っていません',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '食材リストから選んでボウルに追加してください',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _bowlIngredients.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _bowlIngredients[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    item.food.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    '${AmountParser.formatAmount(item.amount)}${item.food.unitLabel} | ${item.calories.round()}kcal (P:${item.protein.toStringAsFixed(1)}g F:${item.fat.toStringAsFixed(1)}g C:${item.carbs.toStringAsFixed(1)}g)',
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                                    tooltip: 'ボウルから削除',
                                    onPressed: () {
                                      setModalState(() {
                                        _bowlIngredients.removeAt(index);
                                      });
                                      setState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),

                    // 合計サマリー ＆ 食事区分 ＆ アクションボタン
                    if (_bowlIngredients.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          border: Border(
                            top: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 栄養サマリー
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('合計エネルギー', style: theme.textTheme.bodyMedium),
                                Text(
                                  '${_bowlCalories.round()} kcal',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'P: ${_bowlProtein.toStringAsFixed(1)}g',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                                Text(
                                  'F: ${_bowlFat.toStringAsFixed(1)}g',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary),
                                ),
                                Text(
                                  'C: ${_bowlCarbs.toStringAsFixed(1)}g',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 食事区分セレクター (朝/昼/夕/間食)
                            Row(
                              children: [
                                Text(
                                  '記録先: ',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SegmentedButton<MealType>(
                                    segments: MealType.values.map((type) {
                                      return ButtonSegment<MealType>(
                                        value: type,
                                        label: Text(type.label, style: const TextStyle(fontSize: 11)),
                                      );
                                    }).toList(),
                                    selected: {_selectedMealType},
                                    onSelectionChanged: (newSelection) {
                                      setModalState(() {
                                        _selectedMealType = newSelection.first;
                                      });
                                      setState(() {});
                                    },
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // アクションボタン
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(bottomSheetContext).pop();
                                      _showSaveRecipeDialog();
                                    },
                                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                                    label: const Text('マイレシピ保存'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(bottomSheetContext).pop();
                                      _submitBowlToMeal();
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('食事に記録'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ボウルに食材を追加 (1/2, 2.5などの分数・小数にも完全対応)
  void _addIngredientToBowl() {
    if (_selectedFoodForBowl == null) return;
    final parsedAmount = AmountParser.parse(_bowlAmountController.text);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分量を正しく入力してください（例: 1/2, 2.5, 100）'),
        ),
      );
      return;
    }

    setState(() {
      _bowlIngredients.add(
        RecipeIngredient(
          food: _selectedFoodForBowl!,
          amount: parsedAmount,
        ),
      );
      _selectedFoodForBowl = null;
    });
  }

  // 食材の単位に応じたクイック分量選択チップ
  Widget _buildQuickAmountChips() {
    if (_selectedFoodForBowl == null) return const SizedBox.shrink();
    final food = _selectedFoodForBowl!;

    final List<Map<String, String>> presets;
    switch (food.unit) {
      case FoodUnit.tablespoon:
        presets = [
          {'label': '小さじ1 (1/3)', 'val': '1/3'},
          {'label': '小さじ2 (2/3)', 'val': '2/3'},
          {'label': '大さじ1/2', 'val': '1/2'},
          {'label': '大さじ1', 'val': '1'},
          {'label': '大さじ2', 'val': '2'},
        ];
        break;
      case FoodUnit.teaspoon:
        presets = [
          {'label': '小さじ1/2', 'val': '1/2'},
          {'label': '小さじ1', 'val': '1'},
          {'label': '小さじ2', 'val': '2'},
          {'label': '大さじ1 (3)', 'val': '3'},
        ];
        break;
      case FoodUnit.piece:
        presets = [
          {'label': '1/2個', 'val': '1/2'},
          {'label': '1個', 'val': '1'},
          {'label': '1.5個', 'val': '1.5'},
          {'label': '2個', 'val': '2'},
          {'label': '2.5個', 'val': '2.5'},
        ];
        break;
      case FoodUnit.serving:
        presets = [
          {'label': '1/2', 'val': '1/2'},
          {'label': '1食', 'val': '1'},
          {'label': '1.5', 'val': '1.5'},
          {'label': '2食', 'val': '2'},
        ];
        break;
      case FoodUnit.g:
        presets = [
          {'label': '50g', 'val': '50'},
          {'label': '100g', 'val': '100'},
          {'label': '150g', 'val': '150'},
          {'label': '200g', 'val': '200'},
        ];
        break;
      case FoodUnit.ml:
        presets = [
          {'label': '50ml', 'val': '50'},
          {'label': '100ml', 'val': '100'},
          {'label': '150ml', 'val': '150'},
          {'label': '200ml', 'val': '200'},
        ];
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((p) {
          final isSelected = _bowlAmountController.text == p['val'];
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(p['label']!, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _bowlAmountController.text = p['val']!;
                });
              },
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  // 保存成功時の共通ハンドラ（UIリセット、通知、画面遷移）
  void _onMealSavedSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    // ボウル食材と直接入力欄のリセット
    setState(() {
      _bowlIngredients.clear();
      _selectedFoodForBowl = null;
      _bowlAmountController.text = '100';
    });
    _nameController.clear();
    _caloriesController.clear();
    _proteinController.clear();
    _fatController.clear();
    _carbsController.clear();

    // モーダルで開かれている場合はpop、ボトムナビからの場合は「今日」タブへ安全に遷移
    if (widget.isModal && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ref.read(navigationIndexProvider.notifier).state = 0;
    }
  }

  // ボウルの内容を食事記録に追加
  void _submitBowlToMeal() {
    if (_bowlIngredients.isEmpty) return;

    final mealItems = _bowlIngredients.map((ing) {
      return MealItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}-${ing.food.id}',
        name: ing.food.name,
        foodId: ing.food.id,
        amount: ing.amount,
        unit: ing.food.unitLabel,
        calories: ing.calories,
        protein: ing.protein,
        fat: ing.fat,
        carbs: ing.carbs,
      );
    }).toList();

    final DateTime targetDate = widget.targetDate ?? ref.read(selectedDateProvider);

    ref.read(mealProvider.notifier).addMealItems(
      date: targetDate,
      type: _selectedMealType,
      items: mealItems,
    );

    _onMealSavedSuccess('${_selectedMealType.label}に${mealItems.length}品の食材を記録しました');
  }

  // マイレシピ保存ダイアログ
  void _showSaveRecipeDialog() {
    if (_bowlIngredients.isEmpty) return;

    final nameController = TextEditingController();
    final descController = TextEditingController();
    int servings = 1;
    MyListCategory category = MyListCategory.homeCooked;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('マイレシピとして保存'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '料理名 *',
                        hintText: '例: 鶏むね肉と野菜の炒め物',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'メモ・説明 (任意)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '分類カテゴリ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<MyListCategory>(
                      segments: MyListCategory.values.map((cat) {
                        return ButtonSegment<MyListCategory>(
                          value: cat,
                          label: Text(cat.shortLabel, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      selected: {category},
                      onSelectionChanged: (newSel) {
                        setDialogState(() {
                          category = newSel.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('何人前分で作りましたか？'),
                        DropdownButton<int>(
                          value: servings,
                          items: [1, 2, 3, 4, 5].map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('$s 人前'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                servings = val;
                              });
                            }
                          },
                        ),
                      ],
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

                    final newRecipe = Recipe(
                      id: 'recipe-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      servings: servings,
                      category: category,
                      ingredients: List.from(_bowlIngredients),
                      createdAt: DateTime.now(),
                    );

                    ref.read(recipeProvider.notifier).addRecipe(newRecipe);
                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('マイレシピ「$name」を保存しました')),
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

  // マイレシピを食事記録に追加（割合・スケール指定に対応）
  void _submitRecipeToMeal(Recipe recipe, {double scale = 1.0}) {
    final batchId = 'recipe-${DateTime.now().millisecondsSinceEpoch}-${recipe.id}';
    final scaleText = scale == 1.0 ? '' : ' ×${scale.toStringAsFixed(1)}';
    final recipeDisplayName = '${recipe.name}$scaleText';

    // レシピの各食材を1人前分 × scale 換算で食事記録に追加
    final mealItems = recipe.ingredients.map((ing) {
      final perServingAmount = (ing.amount / recipe.servings) * scale;
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

    final DateTime targetDate = widget.targetDate ?? ref.read(selectedDateProvider);

    ref.read(mealProvider.notifier).addMealItems(
      date: targetDate,
      type: _selectedMealType,
      items: mealItems,
    );

    _onMealSavedSuccess('「$recipeDisplayName」を${_selectedMealType.label}に記録しました');
  }

  // 直接入力を提出
  void _submitDirectInput() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;

    final item = MealItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      amount: 1.0,
      unit: '食',
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
    );

    final DateTime targetDate = widget.targetDate ?? ref.read(selectedDateProvider);

    ref.read(mealProvider.notifier).addMealItem(
      date: targetDate,
      type: _selectedMealType,
      item: item,
    );

    _onMealSavedSuccess('${_selectedMealType.label}に「$name」を記録しました');
  }

  // 直接入力からマイレシピとして保存
  void _saveDirectInputAsRecipe() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メニュー名を入力してください')),
      );
      return;
    }

    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final protein = double.tryParse(_proteinController.text) ?? 0.0;
    final fat = double.tryParse(_fatController.text) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text) ?? 0.0;

    final nameController = TextEditingController(text: name);
    final descController = TextEditingController();
    int servings = 1;
    MyListCategory category = MyListCategory.ingredient;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('マイレシピとして保存'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '料理・食材名 *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'メモ・説明 (任意)',
                        hintText: '例: 定番プロテイン、お気に入り外食など',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '分類カテゴリ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<MyListCategory>(
                      segments: MyListCategory.values.map((cat) {
                        return ButtonSegment<MyListCategory>(
                          value: cat,
                          label: Text(cat.shortLabel, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      selected: {category},
                      onSelectionChanged: (newSel) {
                        setDialogState(() {
                          category = newSel.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('何人前分ですか？'),
                        DropdownButton<int>(
                          value: servings,
                          items: [1, 2, 3, 4, 5].map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('$s 人前'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                servings = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '合計栄養価 (${calories.toStringAsFixed(1)} kcal)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'P: ${protein.toStringAsFixed(1)}g / F: ${fat.toStringAsFixed(1)}g / C: ${carbs.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
                    final recipeName = nameController.text.trim();
                    if (recipeName.isEmpty) return;

                    // 1食あたりの分量から食材マスタを生成
                    final food = FoodMaster(
                      id: 'food-recipe-${DateTime.now().millisecondsSinceEpoch}',
                      name: recipeName,
                      baseAmount: 1.0,
                      unit: FoodUnit.serving,
                      calories: calories / (servings > 0 ? servings : 1),
                      protein: protein / (servings > 0 ? servings : 1),
                      fat: fat / (servings > 0 ? servings : 1),
                      carbs: carbs / (servings > 0 ? servings : 1),
                      category: 'その他',
                      isCustom: true,
                    );

                    final newRecipe = Recipe(
                      id: 'recipe-${DateTime.now().millisecondsSinceEpoch}',
                      name: recipeName,
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      servings: servings,
                      category: category,
                      ingredients: [
                        RecipeIngredient(food: food, amount: 1.0 * servings),
                      ],
                      createdAt: DateTime.now(),
                    );

                    ref.read(recipeProvider.notifier).addRecipe(newRecipe);
                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('マイレシピ「$recipeName」を保存しました')),
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

  // 新規食材ダイアログを開く
  Future<void> _openAddFoodDialog() async {
    final newFood = await FoodEditDialog.show(context);
    if (newFood != null && mounted) {
      setState(() {
        _selectedFoodForBowl = newFood;
        _bowlAmountController.text = AmountParser.formatAmount(newFood.baseAmount);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${newFood.name}」をライブラリに追加しました')),
      );
    }
  }
}
