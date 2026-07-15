import 'package:flutter/material.dart';
import 'package:hskchat/screens/word_screen.dart';
import 'package:hskchat/screens/game_screen.dart';
import 'package:hskchat/screens/chat_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int currentIndex = 0;
  final List<Widget> _screens = [
    //const ChatScreen(),
    const WordScreen(),
    const GameScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // final AIMesagge =
    return Scaffold(
      backgroundColor: Color(0xFFF7EED8),
      body: _screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xff8B5A2B), width: 2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFF7EED8),
            selectedItemColor: const Color(0xff8B5A2B),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            currentIndex: currentIndex,
            // 현재 활성화된 아이콘
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: const [
              //BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: '단어장',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                label: '학습',
              ),
              //BottomNavigationBarItem(icon: Icon(Icons.settings), label: '채팅'),
            ],
          ),
        ),
      ),
    );
  }
}
