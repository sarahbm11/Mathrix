import 'package:flutter/material.dart';

import 'capture_screen.dart';
import 'chat_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mathrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Capturer un cahier'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CaptureScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.menu_book),
              label: const Text('Notes'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Tuteur'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
