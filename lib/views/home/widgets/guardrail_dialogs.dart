import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_provider.dart';

class GuardrailDialogs {
  /// 停滞期（プラトー）検出時の活動量セルフチェック・ボトムシート
  static Future<void> showPlateauSelfCheckBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            int? selectedChoice; // 1: 普段通り, 2: 減っている

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '停滞期セルフチェック（活動量診断）',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '直近2週間のEMA体重トレンドが横ばいです。無理に食事制限を強化する前に、日常の無意識の活動量（NEAT）を確認しましょう。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Q. 最近、日常の歩数や階段の利用、立ち仕事などの活動量は変化しましたか？',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<int>(
                    value: 1,
                    groupValue: selectedChoice,
                    onChanged: (val) => setState(() => selectedChoice = val),
                    title: const Text('普段通り（変化なし、または増えている）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('運動量や歩数は維持できている', style: TextStyle(fontSize: 11)),
                  ),
                  RadioListTile<int>(
                    value: 2,
                    groupValue: selectedChoice,
                    onChanged: (val) => setState(() => selectedChoice = val),
                    title: const Text('減っている（疲れ・座り仕事が増えた等）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('歩数が減ったり座る時間が増えている気がする', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(height: 16),

                  // 診断結果とアドバイス表示
                  if (selectedChoice == 1)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.water_drop_outlined, color: theme.colorScheme.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '診断: 一時的な「水分貯留」の可能性が高いです',
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '活動量が維持できているため、脂肪は着実に燃焼しています。コルチゾール（ストレスホルモン）による水分貯留が疑われるため、食事をさらに減らす必要はありません。十分な睡眠をとるか、ハイカーボ（リフィード）で水分を排出させましょう。',
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    )
                  else if (selectedChoice == 2)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.tertiary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.directions_walk, color: theme.colorScheme.tertiary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '診断: 無意識の「日常活動量（NEAT）低下」が原因です',
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '減量疲労により、無意識に消費カロリーが低下しています。食事を削りすぎるとさらに代謝が落ちるため、日常の歩数を少し増やす（+1,500〜2,000歩目安）か、軽い散歩を取り入れることを推奨します。',
                            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: selectedChoice == null ? null : () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    child: const Text('理解しました（閉じる）'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// BMR下限防衛時の期日延長・目標緩和ダイアログ
  static Future<void> showExtendDeadlineDialog(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final user = ref.read(userProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: theme.colorScheme.error, size: 24),
              const SizedBox(width: 8),
              const Text('減量期日の延長提案'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '健康維持のため、目標カロリーが基礎代謝（${user.goals.targetCalories.round()} kcal）を下回らないよう下限ガードが適用されています。',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '現在の減量ペースを維持するには過度な食事制限が必要となり、筋肉量の減少やリバウンドの原因となります。達成期日を2週間延ばして安全なペースに調整しませんか？',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('このまま継続'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              icon: const Icon(Icons.event_available),
              label: const Text('期日を2週間延長する'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final newTargetDate = user.targetDate.add(const Duration(days: 14));
      final updatedProfile = user.copyWith(targetDate: newTargetDate);
      ref.read(userProvider.notifier).updateProfile(updatedProfile);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('達成期日を2週間延長し、目標カロリーを安全な水準へ再調整しました！')),
        );
      }
    }
  }
}
