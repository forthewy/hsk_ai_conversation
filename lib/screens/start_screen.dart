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
    const ChatScreen(),
    const WordScreen(),
    const GameScreen(),
  ];


  // void loadMessages() {
  //   //ChatMessage = Hive.box('chat_box');
  //   final AIMessages = ChatMessage.toMap().entries.map().where('role') == 'AI';
  // }
  @override
  Widget build(BuildContext context) {
    // final AIMesagge =
    return Scaffold(
      backgroundColor: Color(0xFFB68B74),
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex, // 현재 활성화된 아이콘
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.sticky_note_2_outlined), label: '단어장'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: '학습시작'),
          //BottomNavigationBarItem(icon: Icon(Icons.settings), label: '채팅'),
        ],
      ),

      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      //
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
