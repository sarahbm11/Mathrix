import 'package:flutter/material.dart';

import '../models/note_chapter.dart';
import '../services/notes_storage_service.dart';
import '../widgets/markdown_math_view.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final _storage = NotesStorageService();
  late TabController _tabController;
  Map<Course, List<NoteChapter>> _chapters = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: Course.values.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = <Course, List<NoteChapter>>{};
    for (final course in Course.values) {
      result[course] = await _storage.listChapters(course);
    }
    setState(() {
      _chapters = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: Course.values.map((c) => Tab(text: c.code)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: Course.values.map((course) {
                final chapters = _chapters[course] ?? [];
                if (chapters.isEmpty) {
                  return const Center(child: Text('Aucune note pour ce cours.'));
                }
                return ListView.builder(
                  itemCount: chapters.length,
                  itemBuilder: (context, i) {
                    final chapter = chapters[i];
                    return ListTile(
                      title: Text(chapter.chapterName),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ChapterDetailScreen(chapter: chapter),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}

class _ChapterDetailScreen extends StatelessWidget {
  final NoteChapter chapter;

  const _ChapterDetailScreen({required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.chapterName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownMathView(text: chapter.content),
      ),
    );
  }
}
