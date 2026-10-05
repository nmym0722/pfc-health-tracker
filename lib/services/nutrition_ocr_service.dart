import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// 栄養成分表示の解析結果モデル
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

/// Gemini Vision API を使用して栄養成分表示をOCR解析するサービス
class NutritionOcrService {
  // secrets_memo.txt より取得したAPIキー
  static const String _defaultApiKey =
      'AQ.Ab8RN6L7CslYZ6nxLiciLNdgjUJGoev1n6wEM8d63NPm4eE4pw';

  final String apiKey;

  NutritionOcrService({String? apiKey}) : apiKey = apiKey ?? _defaultApiKey;

  /// 画像バイト列から栄養成分表示を解析
  Future<NutritionOcrResult> analyzeNutritionImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    const prompt = '''
あなたは食品パッケージに印字されている「栄養成分表示」の画像解析のプロフェッショナルです。
提供された画像から、パッケージ裏や側面の栄養成分表示（および商品名や内容量）を正確に読み取り、以下のJSON形式でのみ出力してください。
Markdownのコードブロック（```json など）や説明文は一切含めず、純粋なJSONオブジェクトのみを返してください。

【出力JSONフォーマット】
{
  "food_name": "商品名や食品名（画像内に記載があれば推測して記載、なければnull）",
  "serving_unit": "栄養成分の基準単位（例: '100g当たり', '1食(50g)当たり', '1袋当たり', '1本当たり'）",
  "net_weight_g": 内容量（グラム数値のみ。mlの場合は概算g。判別できなければnull）,
  "calories": 基準単位あたりのエネルギー (kcal, 数値のみ),
  "protein": 基準単位あたりのたんぱく質 (g, 数値のみ),
  "fat": 基準単位あたりの脂質 (g, 数値のみ),
  "carbs": 基準単位あたりの炭水化物 (g, 数値のみ。糖質と食物繊維に分かれている場合は合算または糖質),
  "total_calories": 内容量全体（1包装・1袋・1本全体）のエネルギー(kcal, 数値のみ。すでに1包装あたりならcaloriesと同じ値。内容量と基準単位から計算可能な場合は計算して記載),
  "total_protein": 1包装全体のたんぱく質 (g, 数値のみ),
  "total_fat": 1包装全体の脂質 (g, 数値のみ),
  "total_carbs": 1包装全体の炭水化物 (g, 数値のみ)
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
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

    if (response.statusCode != 200) {
      // フォールバック: gemini-1.5-flash または詳細エラー処理
      if (response.statusCode == 404 || response.statusCode == 400) {
        return _fallbackToGemini15(imageBytes, mimeType, prompt);
      }
      throw Exception(
        'Gemini API エラー (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return _parseGeminiResponse(response.body);
  }

  Future<NutritionOcrResult> _fallbackToGemini15(
    Uint8List imageBytes,
    String mimeType,
    String prompt,
  ) async {
    final base64Image = base64Encode(imageBytes);
    final fallbackUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
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
      fallbackUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API フォールバックエラー (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    return _parseGeminiResponse(response.body);
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
