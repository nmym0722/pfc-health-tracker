import 'package:flutter/material.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/meal_assist_helper.dart';
import '../../../models/meal_record.dart';

class MealTimelineSection extends StatelessWidget {
  final List<MealRecord> meals;
  final List<MealRecord> previousDayMeals;
  final Function(MealType) onAddMealPressed;
  final Function(String recordId, String itemId) onDeleteItemPressed;
  final Function(String recordId, List<String> itemIds)? onDeleteItemsPressed;
  final Function(String recordId, String itemId, double newAmount)? onUpdateItemAmountPressed;
  final Function(MealType type)? onCopyPreviousMealPressed;
  final Function(MealRecord record)? onSaveMealAsRecipePressed;

  const MealTimelineSection({
    super.key,
    required this.meals,
    this.previousDayMeals = const [],
    required this.onAddMealPressed,
    required this.onDeleteItemPressed,
    this.onDeleteItemsPressed,
    this.onUpdateItemAmountPressed,
    this.onCopyPreviousMealPressed,
    this.onSaveMealAsRecipePressed,
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

        final prevRecord = previousDayMeals.firstWhere(
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
          previousRecord: prevRecord.id.isNotEmpty && prevRecord.items.isNotEmpty ? prevRecord : null,
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
          onUpdateItemAmount: onUpdateItemAmountPressed != null && record.id.isNotEmpty
              ? (item, newAmount) => onUpdateItemAmountPressed!(record.id, item.id, newAmount)
              : null,
          onCopyPreviousPressed: onCopyPreviousMealPressed != null
              ? () => onCopyPreviousMealPressed!(type)
              : null,
          onSaveAsRecipePressed: onSaveMealAsRecipePressed != null && record.id.isNotEmpty
              ? () => onSaveMealAsRecipePressed!(record)
              : null,
        );
      }).toList(),
    );
  }
}

/// タイムライン描画用の表示グループ（単品アイテム or レシピグループ）
class _MealDisplayGroup {
  final String? recipeName;
  final List<MealItem> items;

  /// 食材が2品以上ある組み合わせレシピの場合のみトグルグループとして扱う
  bool get isRecipe => recipeName != null && items.length > 1;

  _MealDisplayGroup({required this.recipeName, required this.items});
}

class _MealCategoryCard extends StatelessWidget {
  final MealType type;
  final MealRecord? record;
  final MealRecord? previousRecord;
  final VoidCallback? onAddPressed;
  final Function(String itemId) onDeletePressed;
  final Function(List<String> itemIds) onDeleteMultiplePressed;
  final Function(MealItem item, double newAmount)? onUpdateItemAmount;
  final VoidCallback? onCopyPreviousPressed;
  final VoidCallback? onSaveAsRecipePressed;

  const _MealCategoryCard({
    required this.type,
    required this.record,
    this.previousRecord,
    this.onAddPressed,
    required this.onDeletePressed,
    required this.onDeleteMultiplePressed,
    this.onUpdateItemAmount,
    this.onCopyPreviousPressed,
    this.onSaveAsRecipePressed,
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
        final groupKey = item.recipeId ?? rName;
        if (!recipeMap.containsKey(groupKey)) {
          final groupItems = <MealItem>[];
          recipeMap[groupKey] = groupItems;
          groups.add(_MealDisplayGroup(recipeName: rName, items: groupItems));
        }
        recipeMap[groupKey]!.add(item);
      } else {
        groups.add(_MealDisplayGroup(recipeName: null, items: [item]));
      }
    }

    return groups;
  }

  Future<void> _showEditAmountDialog(BuildContext context, MealItem item) async {
    if (onUpdateItemAmount == null) return;

    final controller = TextEditingController(
      text: AmountParser.formatAmount(item.amount),
    );
    double previewAmount = item.amount;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final scaled = MealAssistHelper.scaleMealItem(
              item,
              previewAmount > 0 ? previewAmount : item.amount,
            );
            return AlertDialog(
              title: Text(
                '分量を変更',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.cleanIngredientName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '分量 (${item.unit})',
                        hintText: '例: 150, 1/2, 1.5',
                        suffixText: item.unit,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        final parsed = AmountParser.parse(val);
                        if (parsed != null && parsed > 0) {
                          setDialogState(() {
                            previewAmount = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [0.5, 0.8, 1.0, 1.2, 1.5, 2.0].map((mult) {
                        final targetAmt = item.amount * mult;
                        final isSelected = (previewAmount - targetAmt).abs() < 0.01;
                        return ChoiceChip(
                          label: Text(
                            '${mult}x (${AmountParser.formatAmount(targetAmt)}${item.unit})',
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            setDialogState(() {
                              previewAmount = targetAmt;
                              controller.text = AmountParser.formatAmount(targetAmt);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
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
                            '変更後の栄養価: ${scaled.calories.round()} kcal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'P:${scaled.protein.toStringAsFixed(1)}g / F:${scaled.fat.toStringAsFixed(1)}g / C:${scaled.carbs.toStringAsFixed(1)}g',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = AmountParser.parse(controller.text);
                    if (parsed != null && parsed > 0) {
                      onUpdateItemAmount!(item, parsed);
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                  child: const Text('更新する'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = record != null && record!.items.isNotEmpty;
    final hasPrevious = previousRecord != null && previousRecord!.items.isNotEmpty;
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
              // ヘッダー (カテゴリ名 & カロリー合計 & マイレシピ保存/追加ボタン)
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
                  if (hasItems && onSaveAsRecipePressed != null)
                    IconButton(
                      icon: Icon(
                        Icons.bookmark_add_outlined,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'この${type.label}セットをマイレシピに保存',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSaveAsRecipePressed,
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
                    return _RecipeGroupTile(
                      recipeName: group.recipeName!,
                      items: group.items,
                      onDeleteGroup: () {
                        final ids = group.items.map((i) => i.id).toList();
                        onDeleteMultiplePressed(ids);
                      },
                      onDeleteItem: onDeletePressed,
                      onEditItem: onUpdateItemAmount != null
                          ? (item) => _showEditAmountDialog(context, item)
                          : null,
                    );
                  } else {
                    final item = group.items.first;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onUpdateItemAmount != null
                          ? () => _showEditAmountDialog(context, item)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.name,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (onUpdateItemAmount != null) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 13,
                                          color: theme.colorScheme.outline,
                                        ),
                                      ],
                                    ],
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
                      ),
                    );
                  }
                }),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'まだ記録がありません',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (hasPrevious && onCopyPreviousPressed != null)
                      ActionChip(
                        avatar: Icon(
                          Icons.history,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          '前日の${type.label}をコピー (${previousRecord!.totalCalories.round()}kcal)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.35),
                        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                        onPressed: onCopyPreviousPressed,
                      ),
                  ],
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
  final Function(MealItem item)? onEditItem;

  const _RecipeGroupTile({
    required this.recipeName,
    required this.items,
    required this.onDeleteGroup,
    required this.onDeleteItem,
    this.onEditItem,
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
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.menu_book,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
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
                  Text(
                    '${totalCal.round()} kcal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
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
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 6.0, 10.0, 8.0),
              child: Column(
                children: widget.items.map((item) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: widget.onEditItem != null
                        ? () => widget.onEditItem!(item)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.cleanIngredientName,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (widget.onEditItem != null) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 12,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ],
                                  ],
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
