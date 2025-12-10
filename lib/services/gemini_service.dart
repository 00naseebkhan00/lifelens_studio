import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiService {
  // 🔑 PUT YOUR NEW API KEY HERE
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  static const String _model = 'models/gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  Uri _buildUrl() {
    return Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
  }

  /// -----------------------------
  /// SCAN MODE — TEXT INSIGHT
  /// -----------------------------
  static Future<String> analyzeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
  }) async {
    try {
      final service = GeminiService();
      final url = service._buildUrl();

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(imageBytes),
                }
              },
              {
                'text':
                    'You are an assistant in an app called LifeLens Studio. The user shows you an image. '
                        '1) Identify what is in the picture in simple words. '
                        '2) Explain briefly what it is or what is happening. '
                        '3) Give 2–4 short practical tips related to it. '
                        'Format like:\n\nTitle\n\nExplanation\n\nTips:\n- ...\n- ...'
              },
            ]
          }
        ]
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Handle server overload
      if (response.statusCode == 503) {
        return '⚠ Gemini is overloaded right now. Please try again later.';
      }

      if (response.statusCode != 200) {
        return '⚠ AI error: ${response.statusCode}. Please try again.';
      }

      final data = jsonDecode(response.body);
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text is String && text.isNotEmpty) {
        return text;
      } else {
        return '⚠ No response from the AI.';
      }
    } catch (e) {
      if (e.toString().contains('503')) {
        return '⚠ Gemini servers are busy. Try again in a moment.';
      }
      return '⚠ Something went wrong: $e';
    }
  }

  /// -----------------------------
  /// CAPTURE MODE — JSON OUTPUT
  /// -----------------------------
  static Future<Map<String, dynamic>> analyzePhotoForCapture(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
  }) async {
    try {
      final service = GeminiService();
      final url = service._buildUrl();

      final prompt = '''
You are a photography coach inside an app called LifeLens Studio. The user has taken or selected a photo.
Analyze the image and:

1. Give the scene type.
2. Suggest a vibe filter name.
3. Give 2–4 photo improvement tips.

Reply ONLY as JSON in this format:

{
  "scene_type": "string",
  "vibe_filter_name": "string",
  "photography_tips": ["tip1", "tip2", "tip3"]
}
''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Encode(imageBytes),
                }
              },
              {'text': prompt},
            ]
          }
        ],
        'generationConfig': {
          'response_mime_type': 'application/json',
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 503) {
        return {
          'scene_type': 'Unavailable',
          'vibe_filter_name': 'Unavailable',
          'photography_tips': [
            'Gemini is overloaded. Please try again shortly.'
          ]
        };
      }

      if (response.statusCode != 200) {
        return {
          'scene_type': 'Error',
          'vibe_filter_name': '',
          'photography_tips': ['AI error: ${response.statusCode}']
        };
      }

      final data = jsonDecode(response.body);
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'];

      if (text == null || text.isEmpty) {
        return {
          'scene_type': 'Unknown',
          'vibe_filter_name': '',
          'photography_tips': ['No response from AI']
        };
      }

      return jsonDecode(text);
    } catch (e) {
      if (e.toString().contains('503')) {
        return {
          'scene_type': 'Unavailable',
          'vibe_filter_name': '',
          'photography_tips': [
            'Gemini servers are temporarily busy. Try again soon.'
          ]
        };
      }

      return {
        'scene_type': 'Error',
        'vibe_filter_name': '',
        'photography_tips': ['Something went wrong: $e']
      };
    }
  }
}