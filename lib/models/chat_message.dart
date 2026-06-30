enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Format attendu par l'API Claude pour le champ "role".
  String get apiRole => role == MessageRole.user ? 'user' : 'assistant';
}
