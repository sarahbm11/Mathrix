import 'note_chapter.dart';

/// Résumé de fin de session, généré silencieusement et réinjecté comme
/// contexte au début de la session suivante de chat.
class SessionSummary {
  final Course course;
  final DateTime date;
  final String content;
  final String filePath;

  const SessionSummary({
    required this.course,
    required this.date,
    required this.content,
    required this.filePath,
  });
}
