import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/note_chapter.dart';

/// Lecture/écriture des fichiers Markdown de notes, organisés par cours
/// puis chapitre : /notes/NYA/chapitre_X.md, /notes/NYC/chapitre_Y.md.
class NotesStorageService {
  Future<Directory> _courseDir(Course course) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/notes/${course.code}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<NoteChapter> saveChapter({
    required Course course,
    required String chapterName,
    required String content,
  }) async {
    final dir = await _courseDir(course);
    final file = File('${dir.path}/$chapterName.md');
    await file.writeAsString(content);
    return NoteChapter(
      course: course,
      chapterName: chapterName,
      filePath: file.path,
      content: content,
      lastModified: DateTime.now(),
    );
  }

  Future<List<NoteChapter>> listChapters(Course course) async {
    final dir = await _courseDir(course);
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();

    final chapters = <NoteChapter>[];
    for (final file in files) {
      final stat = await file.stat();
      chapters.add(NoteChapter(
        course: course,
        chapterName: file.uri.pathSegments.last.replaceAll('.md', ''),
        filePath: file.path,
        content: await file.readAsString(),
        lastModified: stat.modified,
      ));
    }
    chapters.sort((a, b) => a.chapterName.compareTo(b.chapterName));
    return chapters;
  }

  Future<void> updateChapterContent(NoteChapter chapter, String newContent) {
    return File(chapter.filePath).writeAsString(newContent);
  }
}
