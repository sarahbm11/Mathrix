import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MathrixApp());
}

class MathrixApp extends StatelessWidget {
  const MathrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: MaterialApp(
        title: 'Mathrix',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: const HomeScreen(),
      ),
    );
  }
}
