/// Cours suivis par l'étudiante.
enum Course { nya, nyc }

extension CourseLabel on Course {
  /// Code de cours utilisé dans les chemins de fichiers et l'UI.
  String get code {
    switch (this) {
      case Course.nya:
        return 'NYA';
      case Course.nyc:
        return 'NYC';
    }
  }

  String get displayName {
    switch (this) {
      case Course.nya:
        return 'Calcul différentiel (201-NYA-05)';
      case Course.nyc:
        return 'Algèbre linéaire (201-NYC-05)';
    }
  }
}

/// Un chapitre de notes extraites, stocké en Markdown local.
class NoteChapter {
  final Course course;
  final String chapterName;
  final String filePath;
  final String content;
  final DateTime lastModified;

  const NoteChapter({
    required this.course,
    required this.chapterName,
    required this.filePath,
    required this.content,
    required this.lastModified,
  });
}
