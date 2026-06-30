import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/note_chapter.dart';
import '../providers/chat_provider.dart';
import '../widgets/markdown_math_view.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Course _course = Course.nya;
  late ChatProvider _chatProvider;
  bool _contextLoaded = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _loadContext();
  }

  Future<void> _loadContext() async {
    await _chatProvider.loadContext(_course, null);
    setState(() => _contextLoaded = true);
  }

  Future<void> _changeCourse(Course course) async {
    setState(() {
      _course = course;
      _contextLoaded = false;
    });
    await _loadContext();
  }

  void _send() {
    final text = _controller.text;
    _controller.clear();
    _chatProvider.sendMessage(text);
  }

  @override
  void dispose() {
    // Détecte la fin de session via la fermeture de l'écran et déclenche
    // silencieusement la génération du résumé de mémoire en arrière-plan.
    _chatProvider.endSession();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tuteur'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<Course>(
                value: _course,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: Course.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                    .toList(),
                onChanged: (c) => _changeCourse(c!),
              ),
            ),
          ),
        ),
        body: !_contextLoaded
            ? const Center(child: CircularProgressIndicator())
            : Consumer<ChatProvider>(
                builder: (context, chat, _) => Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, i) {
                          final message = chat.messages[i];
                          final isUser = message.role == MessageRole.user;
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: MarkdownMathView(text: message.content),
                            ),
                          );
                        },
                      ),
                    ),
                    if (chat.isLoading) const LinearProgressIndicator(),
                    if (chat.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(chat.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Pose ta question...',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: chat.isLoading ? null : _send,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
