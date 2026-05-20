import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFB68B74),

      body: SafeArea(
        child: Column(
          children: [
            // 채팅 영역
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Text("채팅 내용"),
                ],
              ),
            ),

            // 입력창 영역
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [

                  // 입력창
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        filled: true,
                        fillColor: Color(0xFFE8E7D4),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 전송 버튼
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      backgroundColor: Color(0xFF457E56),
                    ),
                    child: const Icon(Icons.send, color: Color(0xFFE9DED8),),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}