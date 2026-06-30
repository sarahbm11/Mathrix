import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/note_chapter.dart';
import '../prompts/tutor_system_prompt.dart';
import '../services/claude_api_service.dart';
import '../services/memory_service.dart';
import '../services/notes_storage_service.dart';

/// État et logique du chat tuteur pour un cours/chapitre donné : charge le
/// contexte (notes + dernier résumé de mémoire), envoie les messages à
/// Claude, et déclenche la génération du résumé de session à la fermeture.
class ChatProvider extends ChangeNotifier {
  final ClaudeApiService _api;
  final NotesStorageService _notesStorage;
  final MemoryService _memory;

  ChatProvider({
    ClaudeApiService? api,
    NotesStorageService? notesStorage,
    MemoryService? memory,
  })  : _api = api ?? ClaudeApiService(),
        _notesStorage = notesStorage ?? NotesStorageService(),
        _memory = memory ?? MemoryService();

  final List<ChatMessage> messages = [];
  bool isLoading = false;
  String? error;

  Course? _course;
  String _contextSystemPrompt = tutorSystemPrompt;

  /// Charge les notes du chapitre actif et le dernier résumé de mémoire,
  /// et les injecte dans le system prompt pour la session de chat.
  Future<void> loadContext(Course course, String? chapterName) async {
    _course = course;
    messages.clear();

    final chapters = await _notesStorage.listChapters(course);
    final relevantNotes = chapterName == null
        ? chapters
        : chapters.where((c) => c.chapterName == chapterName).toList();

    final notesText = relevantNotes.isEmpty
        ? '(Aucune note extraite disponible pour ce chapitre.)'
        : relevantNotes.map((c) => '## ${c.chapterName}\n\n${c.content}').join('\n\n');

    final lastSummary = await _memory.getLatestSummary(course);
    final memoryText = lastSummary == null
        ? '(Aucune session précédente.)'
        : lastSummary.content;

    _contextSystemPrompt = '''
$tutorSystemPrompt

## Notes extraites du cahier de l'étudiante pour ce chapitre

$notesText

## Résumé de la session précédente

$memoryText
''';

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    ));
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final reply = await _api.sendChatMessage(
        messages: messages,
        systemPrompt: _contextSystemPrompt,
      );
      messages.add(ChatMessage(
        role: MessageRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// À appeler quand l'utilisatrice quitte l'écran de chat : déclenche en
  /// arrière-plan la génération silencieuse du résumé de session.
  void endSession() {
    if (_course == null || messages.isEmpty) return;
    // Volontairement non attendu : la génération se fait en arrière-plan,
    // sans bloquer la navigation ni nécessiter d'action de l'étudiante.
    _memory.generateAndSaveSummary(course: _course!, messages: messages);
  }
}
