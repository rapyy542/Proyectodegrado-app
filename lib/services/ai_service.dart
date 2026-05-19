import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey =
      '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';
  static const String _model = 'llama-3.1-8b-instant';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
Eres un asistente financiero amigable y claro llamado "Fin".
Tu rol es ayudar a personas jóvenes a entender y mejorar sus hábitos de ahorro.

Reglas importantes:
- Habla en español, de forma simple y cercana, sin tecnicismos
- Nunca juzgues al usuario por sus finanzas
- Da consejos prácticos y alcanzables
- Sé motivador pero realista
- Respuestas cortas y directas (máximo 3 párrafos)
- Si el usuario comparte sus metas, úsalas para dar consejos personalizados
''';

  final List<Map<String, String>> _history = [];

  Future<String> sendMessage(String userMessage, {String? goalsContext}) async {
    String messageWithContext = userMessage;
    if (goalsContext != null && goalsContext.isNotEmpty) {
      messageWithContext =
          'Contexto de mis metas de ahorro: $goalsContext\n\nMi pregunta: $userMessage';
    }

    _history.add({'role': 'user', 'content': messageWithContext});

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                ..._history,
              ],
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': reply});
        return reply;
      } else if (response.statusCode == 401) {
        return '⚠️ La API key de Groq no es válida o expiró. Genera una nueva en groq.com.';
      } else if (response.statusCode == 429) {
        return '⏳ Demasiadas solicitudes. Espera unos segundos e intenta de nuevo.';
      } else {
        return 'Hubo un error al conectar con el asistente (código ${response.statusCode}). Intenta de nuevo.';
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return '⏱️ La conexión tardó demasiado. Verifica tu internet e intenta de nuevo.';
      }
      return '❌ No se pudo conectar. Verifica tu conexión a internet.';
    }
  }

  void clearHistory() {
    _history.clear();
  }
}
