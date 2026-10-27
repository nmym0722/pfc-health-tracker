import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// APIキーが無効または未設定の場合の例外
class InvalidGeminiApiKeyException implements Exception {
  final String message;
  const InvalidGeminiApiKeyException([
    this.message = 'Gemini APIキーが無効、または設定されていません。Google AI Studio (aistudio.google.com) で発行した「AIza...」から始まるキーを設定してください。',
  ]);

  @override
  String toString() => message;
}

/// 栄養成分表示・料理写真の解析結果モデル
class NutritionOcrResult {
  final String? foodName;
  final String? servingUnit;
  final double? netWeightG;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double? totalCalories;
  final double? totalProtein;
  final double? totalFat;
  final double? totalCarbs;
  final String rawResponse;

  NutritionOcrResult({
    this.foodName,
    this.servingUnit,
    this.netWeightG,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.totalCalories,
    this.totalProtein,
    this.totalFat,
    this.totalCarbs,
    required this.rawResponse,
  });

  /// 直接入力フォームに渡すべき優先値（1包装全体の合計があればそれを優先、なければ単位あたりの値）
  double get effectiveCalories => totalCalories ?? calories;
  double get effectiveProtein => totalProtein ?? protein;
  double get effectiveFat => totalFat ?? fat;
  double get effectiveCarbs => totalCarbs ?? carbs;

  factory NutritionOcrResult.fromJson(Map<String, dynamic> json, String rawText) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      final str = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(str) ?? 0.0;
    }

    double? parseOptionalDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      final str = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(str);
    }

    return NutritionOcrResult(
      foodName: json['food_name'] as String?,
      servingUnit: json['serving_unit'] as String?,
      netWeightG: parseOptionalDouble(json['net_weight_g']),
      calories: parseDouble(json['calories']),
      protein: parseDouble(json['protein']),
      fat: parseDouble(json['fat']),
      carbs: parseDouble(json['carbs']),
      totalCalories: parseOptionalDouble(json['total_calories']),
      totalProtein: parseOptionalDouble(json['total_protein']),
      totalFat: parseOptionalDouble(json['total_fat']),
      totalCarbs: parseOptionalDouble(json['total_carbs']),
      rawResponse: rawText,
    );
  }
}

/// Gemini 2.5 Flash API を使用して栄養成分表示や食事写真を解析するサービス
class NutritionOcrService {
  static const String _defaultApiKey =
      'AQ.Ab8RN6L7CslYZ6nxLiciLNdgjUJGoev1n6wEM8d63NPm4eE4pw';

  static const String primaryModel = 'gemini-2.5-flash';
  static const List<String> fallbackModels = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];

  final String? _overrideApiKey;

  NutritionOcrService({String? apiKey}) : _overrideApiKey = apiKey;

  Future<String> _resolveApiKey() async {
    if (_overrideApiKey != null && _overrideApiKey!.trim().isNotEmpty) {
      return _overrideApiKey!.trim();
    }
    final savedKey = await StorageService.loadGeminiApiKey();
    if (savedKey != null && savedKey.isNotEmpty) {
      return savedKey;
    }
    return _defaultApiKey;
  }

  /// 画像バイト列から栄養成分表示（または料理写真）を解析
  Future<NutritionOcrResult> analyzeNutritionImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final activeKey = await _resolveApiKey();
    final base64Image = base64Encode(imageBytes);

    const prompt = '''
あなたは食品パッケージの「栄養成分表示」および「食事写真」の画像解析プロフェッショナルです。
提供された画像に栄養成分表示がある場合は正確に数値を読み取り、料理や食品そのものの写真である場合は見た目と一般的な分量から栄養価（カロリー・PFC）を推定し、以下のJSON形式でのみ出力してください。
Markdownのコードブロック（```json など）や説明文は一切含めず、純粋なJSONオブジェクトのみを返してください。

【出力JSONフォーマット】
{
  "food_name": "商品名や料理名（推測できる場合は記載、不明ならnull）",
  "serving_unit": "栄養成分の基準単位（例: '100g当たり', '1食当たり', '1袋当たり', '推定1人前'）",
  "net_weight_g": 内容量（グラム数値のみ。mlの場合は概算g。判別できなければnull）,
  "calories": 基準単位あたりのエネルギー (kcal, 数値のみ),
  "protein": 基準単位あたりのたんぱく質 (g, 数値のみ),
  "fat": 基準単位あたりの脂質 (g, 数値のみ),
  "carbs": 基準単位あたりの炭水化物 (g, 数値のみ。糖質と食物繊維に分かれている場合は合算または糖質),
  "total_calories": 内容量全体（1包装・1食全体）のエネルギー(kcal, 数値のみ。すでに1包装/1食あたりならcaloriesと同じ値。内容量と基準単位から計算可能な場合は計算して記載),
  "total_protein": 1包装/1食全体のたんぱく質 (g, 数値のみ),
  "total_fat": 1包装/1食全体の脂質 (g, 数値のみ),
  "total_carbs": 1包装/1食全体の炭水化物 (g, 数値のみ)
}
''';

    final modelsToTry = [primaryModel, ...fallbackModels];
    http.Response? lastResponse;

    for (final model in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$activeKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return _parseGeminiResponse(response.body);
      }

      lastResponse = response;

      // APIキー自体が無効な場合 (400 API_KEY_INVALID または 403) は別モデルにフォールバックせず即座に通知
      if (response.statusCode == 400 &&
          (response.body.contains('API_KEY_INVALID') ||
              response.body.contains('key not valid'))) {
        throw const InvalidGeminiApiKeyException();
      }

      // 404 (モデル未対応) や 503 (一時混雑) の場合のみ次のモデルを試行
      if (response.statusCode == 404 || response.statusCode == 503) {
        continue;
      }

      break;
    }

    throw Exception(
      'Gemini 2.5 Flash API エラー (HTTP ${lastResponse?.statusCode}): ${lastResponse?.body}',
    );
  }

  NutritionOcrResult _parseGeminiResponse(String responseBody) {
    final Map<String, dynamic> data = jsonDecode(responseBody);
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Geminiから回答が得られませんでした。');
    }

    final content = candidates[0]['content'];
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Geminiレスポンスのテキストが空です。');
    }

    var text = parts[0]['text'] as String? ?? '';
    text = text.trim();

    // ```json などのマークダウンタグが含まれている場合の除去
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return NutritionOcrResult.fromJson(jsonMap, text);
    } catch (e) {
      throw Exception('栄養成分表示のJSON解析に失敗しました: $e\n受信テキスト: $text');
    }
  }
}
