import 'package:flutter/material.dart';
import 'package:hskchat/screens/start_screen.dart';

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  final wordSearchController = TextEditingController();

  @override
  void dispose() {
    wordSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB68B74),
      body: SafeArea(
        child: Column(
          // 배너 파트
          children: [
            Padding(
              padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
              child: Container(height: 200, color: Colors.grey),
            ),
            // 단어 검색창
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFE8E7D4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: wordSearchController,
              ),
            ),
            // 사전 종류 (문법.단어.채팅? ETC)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.sticky_note_2_outlined),
                  iconSize: 30,
                ), //인기 단어장
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.sticky_note_2_outlined),
                  iconSize: 30,
                ), // 단어장 학습회화
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.sticky_note_2_outlined),
                  iconSize: 30,
                ), // HSK 일정
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.sticky_note_2_outlined),
                  iconSize: 30,
                ), //
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.sticky_note_2_outlined),
                  iconSize: 30,
                ),
              ],
            ),
            // 검색 결과
            Container(color: Colors.grey, height: 200),
          ],
        ),
      ),
    );
  }
}
