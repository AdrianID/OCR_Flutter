import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<String> summarizeText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Please summarize the following text in Indonesian language, make it concise and clear. Do not include any opening statement, just the summary content: $text'
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final summary = data['candidates'][0]['content']['parts'][0]['text'] as String;
        return 'Berikut hasil ringkasan:\n\n$summary';
      } else {
        throw Exception('Failed to summarize text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error summarizing text: $e');
    }
  }
} 