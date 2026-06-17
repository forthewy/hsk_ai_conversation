import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/NPCData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiProvider { gemini, ollama }

class AiService {
  final AiProvider provider;
  static const apiKey = ''; // 제미나이 키

  AiService({this.provider = AiProvider.ollama});

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(maxOutputTokens: 100),
  );

  Future<String> askAI(String text) async {
    try {
      final response = await model.generateContent([
        Content.text('HSK 학습용으로 짧게 답변해줘: $text'),
      ]); // 이부분이 ai 에 보내는 프롬프트
      return response.text ?? '응답없음';
    } catch (e) {
      debugPrint(e.toString());

      return '에러발생';
    }
  }

  Future<String> npcChat({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
  }) async {
    switch (provider) {
      case AiProvider.gemini:
        return geminiNpcChat(
          npc: npc,
          playerMessage: playerMessage,
          playerMemory: playerMemory,
          recentMessages: recentMessages,
        );

      case AiProvider.ollama:
        return ollamaNpcChat(
          npc: npc,
          playerMessage: playerMessage,
          playerMemory: playerMemory,
          recentMessages: recentMessages,
        );
    }
  }

  String buildNpcPrompt({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
  }) {
    final npcMemoryText = npc.memories.isEmpty
        ? '아직 기억한 내용 없음'
        : npc.memories.join('\n');

    final playerMemoryText = playerMemory.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    final recentText = recentMessages.isEmpty
        ? '아직 최근 대화 없음'
        : recentMessages
        .map((m) => '${m['role']}: ${m['content']}')
        .join('\n');

    final prompt =
        '''
      ${npc.systemPrompt}
      
      당신은 NPC입니다.
      
      플레이어에 대한 전역 기억:
      ${playerMemoryText.isEmpty ? '아직 기억 없음' : playerMemoryText}
      
      
      이 NPC만의 기억:
      $npcMemoryText
      
      최근 대화:
      $recentText
      
      플레이어:
      $playerMessage
      
      NPC:
      ''';

    debugPrint('===== PROMPT =====');
    debugPrint(prompt);
    debugPrint('==================');

    return prompt;
  }

  Future<String> geminiNpcChat({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
      );

      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? '응답없음';
    } catch (e) {
      debugPrint('Gemini 오류: $e');

      if (e.toString().contains('503')) {
        return 'AI 사용자 혼잡.';
      }

      return '에러발생';
    }
  }

  Future<String> ollamaNpcChat({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
      );

      final response = await http.post(
        Uri.parse('http://localhost:11434/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'gemma3:4b',
          'prompt': prompt,
          'stream': false,
        }),
      );

      final data = jsonDecode(response.body);

      return data['response'] ?? '응답없음';
    } catch (e) {
      debugPrint('Ollama 오류: $e');
      return '지금은 대답할 수 없어.';
    }
  }
}

//   final response = await http.post(
//     Uri.parse('http://localhost:11434/api/generate'),
