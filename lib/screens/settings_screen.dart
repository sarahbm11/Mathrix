import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await context.read<AppStateProvider>().setApiKey(key);
      setState(() => _message = 'Clé API sauvegardée.');
    } catch (e) {
      setState(() => _message = 'Erreur : $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = context.watch<AppStateProvider>().hasApiKey;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasKey
                  ? 'Une clé API est déjà configurée. Entre une nouvelle clé pour la remplacer.'
                  : 'Aucune clé API configurée. Entre ta clé API Claude (Anthropic) pour activer l\'extraction de notes et le chat.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Clé API Claude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Sauvegarde...' : 'Sauvegarder'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
