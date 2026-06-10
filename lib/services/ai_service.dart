import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/NPCData.dart';

class AiService {
  static const apiKey = '';

  final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 100,
      ),
  );

  Future<String> askAI(String text) async {
    try {
      final response = await model.generateContent([Content.text('HSK 학습용으로 짧게 답변해줘: $text')]); // 이부분이 ai 에 보내는 프롬프트
      return response.text ?? '응답없음';
    } catch (e) {
      debugPrint(e.toString());

      return '에러발생';
    }
  }

  Future<String> npcChat({
    required NPCData npc,
    required String playerMessage,
  }) async {
    try {
      final memoryText = npc.memories.isEmpty? '아직 기억한 내용 없음' : npc.memories.join('\n');
      final prompt = '''
      ${npc.systemPrompt}

      NPC가 기억하는 핵심 정보:
      $memoryText

      플레이어의 말:
      $playerMessage

      위 설정을 지키면서 NPC처럼 짧게 대답하세요.
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? '응답없음';
    } catch (e) {
      debugPrint(e.toString());
      return '에러발생';
    }
  }
}
