import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:hskchat/models/npc_state.dart';

import '../models/npc_data.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'npc_prompt_builder.dart';

enum AiProvider { gemini, ollama }

class AiService {
  final _promptBuilder = NpcPromptBuilder();
  final AiProvider provider;
  static const apiKey = ''; // 제미나이 키

 AiService({this.provider = AiProvider.ollama});
 // AiService({this.provider = AiProvider.gemini});

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
    required List<String> sampledWords,
    required int hskLevel,
    required NpcState state,
  }) async {
    switch (provider) {
      case AiProvider.gemini:
        return geminiNpcChat(
          npc: npc,
          playerMessage: playerMessage,
          playerMemory: playerMemory,
          recentMessages: recentMessages,
          sampledWords: sampledWords,
          hskLevel: hskLevel,
          state: state,
        );

      case AiProvider.ollama:
        return ollamaNpcChat(
          npc: npc,
          playerMessage: playerMessage,
          playerMemory: playerMemory,
          recentMessages: recentMessages,
          sampledWords: sampledWords,
          hskLevel: hskLevel,
          state: state,
        );
    }
  }

  Future<String> geminiNpcChat({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
    required List<String> sampledWords,
    required int hskLevel,
    required NpcState state,
  }) async {
    try {
      final prompt = _promptBuilder.buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
        state:state,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final usage = response.usageMetadata;

      debugPrint("prompt: ${usage?.promptTokenCount}");
      debugPrint("candidate: ${usage?.candidatesTokenCount}");
      debugPrint("total: ${usage?.totalTokenCount}");
      final c = response.candidates.first;

      debugPrint("finish: ${c.finishReason}");
      debugPrint("content: ${c.content.parts}");
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
    required List<String> sampledWords,
    required int hskLevel,
    required NpcState state,
  }) async {
    try {
      final prompt = _promptBuilder.buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
        state:state,
      );
      final watch = Stopwatch()..start();
      final response = await http.post(
        Uri.parse('http://localhost:11434/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'gemma3:4b',
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.3,
            'num_predict': 60,
          },
        }),
      );
          watch.stop();
          debugPrint("HTTP POST: ${watch.elapsedMilliseconds} ms");

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
