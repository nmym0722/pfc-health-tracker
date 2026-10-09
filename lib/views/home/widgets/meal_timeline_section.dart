import 'package:flutter/material.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../models/meal_record.dart';

class MealTimelineSection extends StatelessWidget {
  final List<MealRecord> meals;
  final Function(MealType) onAddMealPressed;
  final Function(String recordId, String itemId) onDeleteItemPressed;
  final Function(String recordId, List<String> itemIds)? onDeleteItemsPressed;

  const MealTimelineSection({
    super.key,
    required this.meals,
    required this.onAddMealPressed,
    required this.onDeleteItemPressed,
    this.onDeleteItemsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: MealType.values.map((type) {
        final record = meals.firstWhere(
          (m) => m.type == type,
          orElse: () => MealRecord(
            id: '',
            date: DateTime.now(),
            type: type,
            items: [],
            createdAt: DateTime.now(),
          ),
        );

        return _MealCategoryCard(
          type: type,
          record: record.id.isNotEmpty ? record : null,
          onAddPressed: () => onAddMealPressed(type),
          onDeletePressed: (itemId) => onDeleteItemPressed(record.id, itemId),
          onDeleteMultiplePressed: (itemIds) {
            if (onDeleteItemsPressed != null) {
              onDeleteItemsPressed!(record.id, itemIds);
            } else {
              for (final id in itemIds) {
                onDeleteItemPressed(record.id, id);
              }
            }
          },
        );
      }).toList(),
    );
  }
}

/// タイムライン描画用の表示グループ（単品アイテム or レシピグループ）
class _MealDisplayGroup {
  final String? recipeName;
  final List<MealItem> items;

  bool get isRecipe => recipeName != null && items.isNotEmpty;

  _MealDisplayGroup({required this.recipeName, required this.items});
}

class _MealCategoryCard extends StatelessWidget {
  final MealType type;
  final MealRecord? record;
  final VoidCallback onAddPressed;
  final Function(String itemId) onDeletePressed;
  final Function(List<String> itemIds) onDeleteMultiplePressed;

  const _MealCategoryCard({
    required this.type,
    required this.record,
    required this.onAddPressed,
    required this.onDeletePressed,
    required this.onDeleteMultiplePressed,
  });

  IconData _getCategoryIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.light_mode_outlined;
      case MealType.dinner:
        return Icons.nightlight_round_outlined;
      case MealType.snack:
        return Icons.local_cafe_outlined;
    }
  }

  /// アイテム一覧をレシピ単位および単品単位にグループ化
  List<_MealDisplayGroup> _groupItems(List<MealItem> items) {
    final List<_MealDisplayGroup> groups = [];
    final Map<String, List<MealItem>> recipeMap = {};

    for (final item in items) {
      final rName = item.associatedRecipeName;
      if (rName != null && rName.isNotEmpty) {
        // 同一バッチまたは同一レシピ名でまとめる
        final groupKey = item.recipeId ?? rName;
        if (!recipeMap.containsKey(groupKey)) {
          final groupItems = <MealItem>[];
          recipeMap[groupKey] = groupItems;
          groups.add(_MealDisplayGroup(recipeName: rName, items: groupItems));
        }
        recipeMap[groupKey]!.add(item);
      } else {
        // 単品アイテム
        groups.add(_MealDisplayGroup(recipeName: null, items: [item]));
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = record != null && record!.items.isNotEmpty;
    final displayGroups = hasItems ? _groupItems(record!.items) : <_MealDisplayGroup>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー (カテゴリ名 & カロリー合計 & 追加ボタン)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(type),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasItems) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${record!.totalCalories.round()} kcal)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('追加'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),

              // アイテムリスト（グループ表示）
              if (hasItems) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...displayGroups.map((group) {
                  if (group.isRecipe) {
                    // レシピグループ（折りたたみトグル対応）
                    return _RecipeGroupTile(
                      recipeName: group.recipeName!,
                      items: group.items,
                      onDeleteGroup: () {
                        final ids = group.items.map((i) => i.id).toList();
                        onDeleteMultiplePressed(ids);
                      },
                      onDeleteItem: onDeletePressed,
                    );
                  } else {
                    // 単品アイテム
                    final item = group.items.first;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'P:${item.protein.toStringAsFixed(1)}g / F:${item.fat.toStringAsFixed(1)}g / C:${item.carbs.toStringAsFixed(1)}g (${AmountParser.formatAmount(item.amount)}${item.unit})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${item.calories.round()} kcal',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () => onDeletePressed(item.id),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                }),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'まだ記録がありません',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// マイレシピ用トグル開閉Tileコンポーネント
class _RecipeGroupTile extends StatefulWidget {
  final String recipeName;
  final List<MealItem> items;
  final VoidCallback onDeleteGroup;
  final Function(String itemId) onDeleteItem;

  const _RecipeGroupTile({
    required this.recipeName,
    required this.items,
    required this.onDeleteGroup,
    required this.onDeleteItem,
  });

  @override
  State<_RecipeGroupTile> createState() => _RecipeGroupTileState();
}

class _RecipeGroupTileState extends State<_RecipeGroupTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCal = widget.items.fold(0.0, (sum, i) => sum + i.calories);
    final totalP = widget.items.fold(0.0, (sum, i) => sum + i.protein);
    final totalF = widget.items.fold(0.0, (sum, i) => sum + i.fat);
    final totalC = widget.items.fold(0.0, (sum, i) => sum + i.carbs);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: _isExpanded
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isExpanded
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // レシピサマリー行（タップでトグル開閉）
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                children: [
                  // トグル開閉アイコン
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  // レシピアイコン
                  Icon(
                    Icons.menu_book,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  // レシピ名 & 合算PFCサマリー
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.recipeName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.items.length}品',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'P:${totalP.toStringAsFixed(1)}g / F:${totalF.toStringAsFixed(1)}g / C:${totalC.toStringAsFixed(1)}g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 合算カロリー
                  Text(
                    '${totalCal.round()} kcal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // レシピ一括削除ボタン
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'レシピ全体を削除',
                    onPressed: widget.onDeleteGroup,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ),
          ),

          // 開いた時の食材内訳アコーディオン
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 10.0, 8.0),
              child: Column(
                children: widget.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.cleanIngredientName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'P:${item.protein.toStringAsFixed(1)}g / F:${item.fat.toStringAsFixed(1)}g / C:${item.carbs.toStringAsFixed(1)}g (${AmountParser.formatAmount(item.amount)}${item.unit})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${item.calories.round()} kcal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 14,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: 'この食材を削除',
                              onPressed: () => widget.onDeleteItem(item.id),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

