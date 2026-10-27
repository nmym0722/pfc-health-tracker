import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/food_master_provider.dart';

/// マイレシピ登録・編集用のグループ選択・新規作成ウィジェット
class RecipeGroupSelector extends ConsumerWidget {
  final String selectedGroup;
  final ValueChanged<String> onGroupChanged;

  const RecipeGroupSelector({
    super.key,
    required this.selectedGroup,
    required this.onGroupChanged,
  });

  /// 新規グループ作成ダイアログを開く
  static Future<String?> showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新しいグループを作成'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'グループ名',
            hintText: '例: 朝食定番, プロテイン, コンビニ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(recipeGroupsProvider.notifier).addGroup(name);
                Navigator.of(ctx).pop(name);
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allGroups = ref.watch(recipeGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '分類グループ',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                final newGroup = await showCreateGroupDialog(context, ref);
                if (newGroup != null && newGroup.isNotEmpty) {
                  onGroupChanged(newGroup);
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('グループを追加', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: allGroups.map((group) {
            final isSelected = selectedGroup == group;
            final isDefault = RecipeGroupsNotifier.defaultGroups.contains(group);

            return InputChip(
              label: Text(group, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              showCheckmark: isSelected,
              onSelected: (_) => onGroupChanged(group),
              onDeleted: isDefault
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('グループ削除'),
                          content: Text('グループ「$group」を削除しますか？\n（このグループに登録されたレシピは削除されません）'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('キャンセル'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('削除'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        ref.read(recipeGroupsProvider.notifier).removeGroup(group);
                        if (selectedGroup == group) {
                          onGroupChanged('自炊');
                        }
                      }
                    },
              deleteIcon: isDefault ? null : const Icon(Icons.close, size: 14),
              deleteButtonTooltipMessage: 'このグループを削除',
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}
