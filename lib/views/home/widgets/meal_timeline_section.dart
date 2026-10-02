import 'package:flutter/material.dart';
import '../../../models/meal_record.dart';

class MealTimelineSection extends StatelessWidget {
  final List<MealRecord> meals;
  final Function(MealType) onAddMealPressed;
  final Function(String recordId, String itemId) onDeleteItemPressed;

  const MealTimelineSection({
    super.key,
    required this.meals,
    required this.onAddMealPressed,
    required this.onDeleteItemPressed,
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
        );
      }).toList(),
    );
  }
}

class _MealCategoryCard extends StatelessWidget {
  final MealType type;
  final MealRecord? record;
  final VoidCallback onAddPressed;
  final Function(String itemId) onDeletePressed;

  const _MealCategoryCard({
    required this.type,
    required this.record,
    required this.onAddPressed,
    required this.onDeletePressed,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasItems = record != null && record!.items.isNotEmpty;

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

              // アイテムリスト
              if (hasItems) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...record!.items.map((item) => Padding(
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
                                  'P:${item.protein.toStringAsFixed(1)}g / F:${item.fat.toStringAsFixed(1)}g / C:${item.carbs.toStringAsFixed(1)}g (${item.amount}${item.unit})',
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
                    )),
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
