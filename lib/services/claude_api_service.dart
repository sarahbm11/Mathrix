import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'secure_storage_service.dart';

/// Appels à l'API Claude (Anthropic) via le endpoint /v1/messages.
///
/// Modèle imposé : claude-sonnet-4-6, pour l'extraction vision et le chat.
/// Ne pas remplacer par un autre nom de modèle.
class ClaudeApiService {
  static const _model = 'claude-sonnet-4-6';
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _anthropicVersion = '2023-06-01';
  static const _maxTokens = 4096;

  final SecureStorageService _secureStorage;
  final http.Client _client;

  ClaudeApiService({
    SecureStorageService? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorageService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final apiKey = await _secureStorage.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError(
        'Aucune clé API Claude configurée. Configure-la dans les paramètres.',
      );
    }
    return {
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': _anthropicVersion,
    };
  }

  /// Envoie une liste de chemins de fichiers image (frames extraites) à
  /// Claude vision avec [systemPrompt] et [userPrompt], et retourne le
  /// texte de la réponse (transcription Markdown attendue).
  Future<String> extractNotesFromFrames({
    required List<String> framePaths,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final content = <Map<String, dynamic>>[];
    for (final path in framePaths) {
      final bytes = await File(path).readAsBytes();
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/png',
          'data': base64Encode(bytes),
        },
      });
    }
    content.add({'type': 'text', 'text': userPrompt});

    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'system': systemPrompt,
      'messages': [
        {'role': 'user', 'content': content},
      ],
    };

    return _sendAndExtractText(body);
  }

  /// Envoie l'historique de chat [messages] avec [systemPrompt] (tuteur +
  /// notes du chapitre + résumé de mémoire injectés en amont dans le
  /// system prompt par l'appelant) et retourne la réponse du tuteur.
  Future<String> sendChatMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
  }) async {
    final body = {
      'model': _model,
      'max_tokens': _maxTokens,
      'system': systemPrompt,
      'messages': messages
          .map((m) => {'role': m.apiRole, 'content': m.content})
          .toList(),
    };

    return _sendAndExtractText(body);
  }

  Future<String> _sendAndExtractText(Map<String, dynamic> body) async {
    final response = await _client.post(
      Uri.parse(_apiUrl),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur API Claude (${response.statusCode}) : ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final blocks = decoded['content'] as List<dynamic>;
    return blocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n');
  }
}
