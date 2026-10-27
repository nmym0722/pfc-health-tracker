import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/nutrition_ocr_service.dart';
import '../../services/storage_service.dart';
import '../../core/utils/image_picker_helper.dart';

/// 栄養成分表示・料理写真の写真撮影・画像選択モーダルシート
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
  final _apiKeyController = TextEditingController();
  bool _isAnalyzing = false;
  bool _showApiKeyEditor = false;
  String? _statusMessage;
  String? _errorMessage;
  ({Uint8List bytes, String mimeType})? _pendingImageData;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  Future<void> _loadSavedApiKey() async {
    final saved = await StorageService.loadGeminiApiKey();
    if (saved != null && mounted) {
      setState(() {
        _apiKeyController.text = saved;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  /// カメラまたはギャラリーから画像を取得して解析
  Future<void> _pickAndAnalyze({required bool isCamera}) async {
    if (_isAnalyzing) return;

    try {
      final pickedData = isCamera
          ? await AppImagePicker.takePhoto()
          : await AppImagePicker.pickFromGallery();

      if (pickedData == null) {
        return;
      }

      _pendingImageData = pickedData;
      await _runAnalysis(pickedData);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _statusMessage = null;
        _errorMessage = '写真の読み取りに失敗しました: $e';
      });
    }
  }

  Future<void> _runAnalysis(({Uint8List bytes, String mimeType}) pickedData) async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _statusMessage = 'Gemini 2.5 Flash で栄養成分を解析中...';
    });

    try {
      final result = await _ocrService.analyzeNutritionImage(
        pickedData.bytes,
        mimeType: pickedData.mimeType,
      );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on InvalidGeminiApiKeyException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _statusMessage = null;
        _showApiKeyEditor = true;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _statusMessage = null;
        _errorMessage = '解析エラー: $e';
      });
    }
  }

  Future<void> _saveApiKeyAndRetry() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    await StorageService.saveGeminiApiKey(key);
    if (!mounted) return;

    setState(() {
      _showApiKeyEditor = false;
      _errorMessage = null;
    });

    if (_pendingImageData != null) {
      await _runAnalysis(_pendingImageData!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini APIキーを保存しました')),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 上部ドラッグハンドル
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // タイトル & API設定ボタン
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '写真から栄養成分を読み取る',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showApiKeyEditor = !_showApiKeyEditor;
                      });
                    },
                    icon: const Icon(Icons.key_outlined, size: 16),
                    label: const Text('APIキー設定', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '食品パッケージの栄養成分表示、または料理の写真を撮影・選択してください。Gemini 2.5 Flash がカロリー・PFCを自動計算します。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_showApiKeyEditor) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Gemini APIキー (Google AI Studio)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'aistudio.google.com/apikey で無料発行できる「AIza...」から始まるキーを入力してください。',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        decoration: const InputDecoration(
                          hintText: 'AIzaSy...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _saveApiKeyAndRetry,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: Text(
                          _pendingImageData != null ? 'キーを保存して再解析する' : 'APIキーを保存',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

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
      ),
    );
  }
}
