import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/note_chapter.dart';
import '../prompts/extraction_prompt.dart';
import '../prompts/tutor_system_prompt.dart' show tutorSystemPrompt;
import '../providers/app_state_provider.dart';
import '../services/claude_api_service.dart';
import '../services/notes_storage_service.dart';
import '../services/video_frame_service.dart';
import '../widgets/markdown_math_view.dart';

enum _Step { pickVideo, reviewFrames, extracting, done }

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _frameService = VideoFrameService();
  final _api = ClaudeApiService();
  final _notesStorage = NotesStorageService();
  final _chapterController = TextEditingController();

  _Step _step = _Step.pickVideo;
  String? _videoPath;
  List<String> _frames = [];
  String? _extractedMarkdown;
  String? _error;
  Course _selectedCourse = Course.nya;

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: source);
    if (video == null) return;

    setState(() {
      _videoPath = video.path;
      _error = null;
    });
    await _extractAndDeduplicate();
  }

  Future<void> _extractAndDeduplicate() async {
    if (_videoPath == null) return;
    setState(() {
      _step = _Step.extracting;
    });

    try {
      final raw = await _frameService.extractFrames(_videoPath!);
      final deduped = await _frameService.deduplicateFrames(raw);
      setState(() {
        _frames = deduped;
        _step = _Step.reviewFrames;
      });
    } catch (e) {
      setState(() {
        _error = 'Échec de l\'extraction de frames : $e';
        _step = _Step.pickVideo;
      });
    }
  }

  Future<void> _confirmAndSendToApi() async {
    if (_frames.isEmpty || _chapterController.text.trim().isEmpty) return;

    setState(() {
      _step = _Step.extracting;
      _error = null;
    });

    try {
      final markdown = await _api.extractNotesFromFrames(
        framePaths: _frames,
        systemPrompt: tutorSystemPrompt,
        userPrompt: extractionPrompt,
      );
      await _notesStorage.saveChapter(
        course: _selectedCourse,
        chapterName: _chapterController.text.trim(),
        content: markdown,
      );
      setState(() {
        _extractedMarkdown = markdown;
        _step = _Step.done;
      });
    } catch (e) {
      setState(() {
        _error = 'Échec de l\'extraction de notes : $e';
        _step = _Step.reviewFrames;
      });
    }
  }

  void _reset() {
    setState(() {
      _step = _Step.pickVideo;
      _videoPath = null;
      _frames = [];
      _extractedMarkdown = null;
      _error = null;
      _chapterController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = context.watch<AppStateProvider>().hasApiKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Capturer un cahier')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(hasApiKey),
      ),
    );
  }

  Widget _buildBody(bool hasApiKey) {
    if (!hasApiKey) {
      return const Center(
        child: Text(
          'Configure d\'abord ta clé API dans les paramètres pour pouvoir extraire des notes.',
        ),
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _reset, child: const Text('Recommencer')),
        ],
      );
    }

    switch (_step) {
      case _Step.pickVideo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickVideo(ImageSource.camera),
              icon: const Icon(Icons.videocam),
              label: const Text('Filmer le cahier'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _pickVideo(ImageSource.gallery),
              icon: const Icon(Icons.video_library),
              label: const Text('Importer une vidéo'),
            ),
          ],
        );

      case _Step.extracting:
        return const Center(child: CircularProgressIndicator());

      case _Step.reviewFrames:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${_frames.length} frames retenues après déduplication.'),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: _frames.length,
                itemBuilder: (context, i) => Image.file(File(_frames[i])),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<Course>(
              value: _selectedCourse,
              isExpanded: true,
              items: Course.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                  .toList(),
              onChanged: (c) => setState(() => _selectedCourse = c!),
            ),
            TextField(
              controller: _chapterController,
              decoration: const InputDecoration(labelText: 'Nom du chapitre (ex. chapitre_3)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _confirmAndSendToApi,
              child: Text(
                'Envoyer ${_frames.length} frames à Claude pour extraction',
              ),
            ),
          ],
        );

      case _Step.done:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Notes extraites et sauvegardées.'),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: MarkdownMathView(text: _extractedMarkdown ?? ''),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _reset, child: const Text('Capturer un autre cahier')),
          ],
        );
    }
  }
}
