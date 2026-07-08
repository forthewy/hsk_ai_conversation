import 'package:flutter/material.dart';
import 'package:hskchat/screens/start_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hskchat/viewmodels/word_view_model.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('chat_box');
  await Hive.openBox('npc_memory_box');
  await Hive.openBox('player_memory_box');
  await Hive.openBox('word_status_box');
  runApp(
    ChangeNotifierProvider(
      create: (_) => WordViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      // 공용 UI
      routes: {'/': (context) => StartScreen()},
    );
  }
}
