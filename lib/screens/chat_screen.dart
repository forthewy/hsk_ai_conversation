import 'package:flutter/material.dart';
import 'package:hskchat/services/ai_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  var chatBox = Hive.box('chat_box');
  final messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final aiService = ;//AiService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMessage();
  }

  void loadMessage() {
    final loaded = chatBox.toMap().entries.map((entry) {
      return Map<String, dynamic>.from(entry.value);
    }).toList();

    setState(() {
      messages = loaded;
    });
  }

  // 유저 메시지
  Future<void> addUserMessage(String message) async {
    final newMessage = {
      'role': 'user',
      'text': message,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await chatBox.add(newMessage);

    setState(() {
      messages.add(newMessage);
    });
  }

  // AI 메시지
  Future<void> addAIMessage(String message) async {
    final newMessage = {
      'role': 'AI',
      'text': message,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await chatBox.add(newMessage);

    setState(() {
      messages.add(newMessage);
    });
  }

  // 메세지 보내기
  Future<void> sendMessage() async {
    if (isLoading) return;
    isLoading = true;
    debugPrint('sendMessage 실행');
    final text = messageController.text.trim();
    if (text.isEmpty) {
      isLoading = false;
      return;
    }
    await addUserMessage(text);
    messageController.clear();
    final aiReply = 'aiReply'; //await aiService.askAI(text);
    debugPrint(aiReply);
    await addAIMessage(aiReply);
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 채팅 영역
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message['role'] == 'AI'
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: message['role'] == 'AI' ? Colors.grey : Colors.white,
                    child: Padding(
                      padding: const EdgeInsetsGeometry.all(12),
                      child: Text(message['text']),
                    ),
                  ),
                );
              },
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
                    controller: messageController,
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
                    onSubmitted: (_) async {
                      await sendMessage();
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // 전송 버튼
                ElevatedButton(
                  onPressed: sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    backgroundColor: Color(0xFF457E56),
                  ),
                  child: const Icon(Icons.send, color: Color(0xFFE9DED8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
