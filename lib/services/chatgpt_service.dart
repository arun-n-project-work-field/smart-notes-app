import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatGptService {
  final String _apiKey =
      "";

  Future<String> getChatGptResponse(
    String prompt, {
    int maxTokens = 400,
    String model = "gpt-3.5-turbo",
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = json.encode({
      "model": model,
      "messages": [
        {"role": "user", "content": prompt},
      ],
      "max_tokens": maxTokens,
      "temperature": 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['choices'][0]['message']['content'].trim();
      } else {
        print("API error: ${response.body}");
        throw Exception('API request failed: ${response.body}');
      }
    } catch (e) {
      print("ChatGptService error: $e");
      throw Exception('Error: $e');
    }
  }
}
