import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';
import '../models/note_chapter.dart';
import '../models/session_summary.dart';
import 'claude_api_service.dart';

const String _memorySummaryPrompt = '''
La session de tutorat suivante vient de se terminer. Génère un résumé concis
(en français, en Markdown) contenant trois sections :

1. Notions couvertes pendant la session.
2. Comment l'étudiante a reformulé ces notions dans ses propres mots (signal
   clé de ce qui est réellement compris vs simplement reconnu).
3. Points où l'intuition n'était pas encore solide ou où elle a buté.

Ne produis que ce résumé Markdown, sans commentaire additionnel.
''';

/// Génération et persistance des résumés de session automatiques, qui
/// servent de mémoire injectée au début de la session suivante de chat.
class MemoryService {
  final ClaudeApiService _api;

  MemoryService({ClaudeApiService? api}) : _api = api ?? ClaudeApiService();

  Future<Directory> _courseDir(Course course) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/memoire/${course.code}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Génère silencieusement, en arrière-plan, un résumé de la session de
  /// chat [messages] et le sauvegarde dans /memoire/{cours}/session_{date}.md.
  Future<SessionSummary> generateAndSaveSummary({
    required Course course,
    required List<ChatMessage> messages,
  }) async {
    if (messages.isEmpty) {
      throw ArgumentError('Aucun message à résumer.');
    }

    final transcript = messages
        .map((m) => '${m.role == MessageRole.user ? 'Étudiante' : 'Tuteur'}: ${m.content}')
        .join('\n\n');

    final summaryContent = await _api.sendChatMessage(
      systemPrompt: _memorySummaryPrompt,
      messages: [
        ChatMessage(
          role: MessageRole.user,
          content: transcript,
          timestamp: DateTime.now(),
        ),
      ],
    );

    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dir = await _courseDir(course);
    final file = File('${dir.path}/session_$dateStr.md');
    await file.writeAsString(summaryContent);

    return SessionSummary(
      course: course,
      date: date,
      content: summaryContent,
      filePath: file.path,
    );
  }

  /// Retourne le contenu du résumé de session le plus récent pour [course],
  /// ou null si aucune session précédente n'existe.
  Future<SessionSummary?> getLatestSummary(Course course) async {
    final dir = await _courseDir(course);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (files.isEmpty) return null;

    final file = files.first;
    final stat = await file.stat();
    return SessionSummary(
      course: course,
      date: stat.modified,
      content: await file.readAsString(),
      filePath: file.path,
    );
  }
}
