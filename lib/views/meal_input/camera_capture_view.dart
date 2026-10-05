import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// カメラ撮影 & カメラロール選択用のビュー
class CameraCaptureView extends StatefulWidget {
  final Function(Uint8List imageBytes, String mimeType) onImageSelected;
  final bool isAnalyzing;

  const CameraCaptureView({
    super.key,
    required this.onImageSelected,
    this.isAnalyzing = false,
  });

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = '利用可能なカメラが見つかりませんでした。';
          });
        }
        return;
      }

      // 背面カメラを優先、なければ最初のカメラ
      final camera = _cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'カメラの起動に失敗しました: $e';
        });
      }
    }
  }

  /// シャッターボタンタップ時の撮影処理
  Future<void> _takePicture() async {
    if (widget.isAnalyzing) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      // カメラが使えない場合はカメラロール呼び出しへ
      _pickFromGallery();
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      final bytes = await xFile.readAsBytes();
      final mimeType = xFile.mimeType ?? 'image/jpeg';
      widget.onImageSelected(bytes, mimeType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('撮影に失敗しました: $e')),
        );
      }
    }
  }

  /// カメラロール（ギャラリー）からの画像選択
  Future<void> _pickFromGallery() async {
    if (widget.isAnalyzing) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';
        widget.onImageSelected(bytes, mimeType);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の選択に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. カメラプレビュー または フォールバック表示
        if (_isCameraInitialized && _cameraController != null)
          ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 400,
                  height: _cameraController!.value.previewSize?.width ?? 600,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          )
        else
          _buildCameraFallback(theme),

        // 2. 撮影ガイド枠（中央）
        if (_isCameraInitialized)
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '枠内に栄養成分表示を合わせてください',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. 解析中ローディングオーバーレイ
        if (widget.isAnalyzing)
          Container(
            color: Colors.black.withOpacity(0.75),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'AIが栄養成分表示を読み取り中...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'カロリー・PFC・内容量を解析しています',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 4. 下部コントロールバー（シャッターボタン & カメラロール選択）
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左下: カメラロールから選択ボタン
                  IconButton(
                    onPressed: widget.isAnalyzing ? null : _pickFromGallery,
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    tooltip: 'カメラロールから選択',
                  ),

                  // 下部中央: シャッターボタン
                  GestureDetector(
                    onTap: widget.isAnalyzing ? null : _takePicture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 右下のダミースペース（中央揃えのバランス用・カメラ反転アイコンにも利用可能）
                  const SizedBox(width: 50),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// カメラが利用できない場合（Webや権限なしなど）のフォールバック画面
  Widget _buildCameraFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '栄養成分表示の写真を読み取る',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'カメラを準備中、または写真を選択してください',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.isAnalyzing ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('カメラロールから写真を選択'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('カメラを再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
