import 'package:flutter/material.dart';
import '../../services/nutrition_ocr_service.dart';
import '../../core/utils/image_picker_helper.dart';

/// 栄養成分表示の写真撮影・画像選択モーダルシート
class NutritionPhotoPickerSheet extends StatefulWidget {
  const NutritionPhotoPickerSheet({super.key});

  /// ボトムシートを表示して解析結果を取得するヘルパー
  static Future<NutritionOcrResult?> show(BuildContext context) {
    return showModalBottomSheet<NutritionOcrResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NutritionPhotoPickerSheet(),
    );
  }

  @override
  State<NutritionPhotoPickerSheet> createState() =>
      _NutritionPhotoPickerSheetState();
}

class _NutritionPhotoPickerSheetState extends State<NutritionPhotoPickerSheet> {
  final _ocrService = NutritionOcrService();
  bool _isAnalyzing = false;
  String? _statusMessage;

  /// カメラまたはギャラリーから画像を取得して解析
  Future<void> _pickAndAnalyze({required bool isCamera}) async {
    if (_isAnalyzing) return;

    try {
      final pickedData = isCamera
          ? await AppImagePicker.takePhoto()
          : await AppImagePicker.pickFromGallery();

      if (pickedData == null) {
        // ユーザーが選択をキャンセルした場合
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _statusMessage = '栄養成分表示をAIが解析中...';
      });

      final result = await _ocrService.analyzeNutritionImage(
        pickedData.bytes,
        mimeType: pickedData.mimeType,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('写真の読み取り・解析に失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 上部ドラッグハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // タイトル
            Text(
              '栄養成分表示の写真を読み取る',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '食品パッケージ裏の栄養成分表を撮影、または写真を選択してください。カロリー・PFCを自動計算して入力します。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            if (_isAnalyzing) ...[
              // 解析中のプログレス表示
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 18),
                    Text(
                      _statusMessage ?? '画像を解析しています...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '内容量・カロリー・PFCを抽出中',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 選択アクションボタン
              // 1. カメラで撮影
              FilledButton.icon(
                onPressed: () => _pickAndAnalyze(isCamera: true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('カメラで撮影する'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. 写真ライブラリから選択
              OutlinedButton.icon(
                onPressed: () => _pickAndAnalyze(isCamera: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('写真ライブラリ・ファイルから選択'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // キャンセルボタン
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
