import 'package:flutter/foundation.dart';

import '../models/note_chapter.dart';
import '../services/secure_storage_service.dart';

/// État global partagé : clé API configurée ou non, cours/chapitre actif
/// pour le chat.
class AppStateProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage;

  AppStateProvider({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    _loadApiKeyStatus();
  }

  bool _hasApiKey = false;
  bool get hasApiKey => _hasApiKey;

  Course activeCourse = Course.nya;
  String? activeChapterName;

  Future<void> _loadApiKeyStatus() async {
    final key = await _secureStorage.getApiKey();
    _hasApiKey = key != null && key.isNotEmpty;
    notifyListeners();
  }

  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.saveApiKey(apiKey);
    _hasApiKey = true;
    notifyListeners();
  }

  void setActiveCourse(Course course) {
    activeCourse = course;
    activeChapterName = null;
    notifyListeners();
  }

  void setActiveChapter(String chapterName) {
    activeChapterName = chapterName;
    notifyListeners();
  }
}
