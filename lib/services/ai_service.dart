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

  String getHskPrompt(int level) {
    switch (level) {
      case 1:
        return '''
사용자는 HSK1 학습자입니다.

가능한 대화 주제:
- 자기소개
- 가족
- 숫자
- 시간
- 장소
- 좋아하는 것
- 소유
- 식사
- 간단한 질문

모르는 단어는 거의 사용하지 마세요.
첫인사는 이미 끝났습니다. 첫인사를 또 하지 마세요
''';

      case 2:
        return '''
사용자는 HSK2 학습자입니다.

가능한 대화 주제:
- HSK1 주제
- 시간
- 능력
- 희망
- 이유
- 정도
- 행동

모르는 단어 1~2개 정도는 사용 가능합니다.
''';

      case 3:
        return '''
사용자는 HSK3 학습자입니다.

일상 회화를 자연스럽게 진행하세요.
모르는 단어를 2~3개 포함할 수 있습니다.
''';

      default:
        return '''
사용자는 HSK$level 학습자입니다.
''';
    }
  }

  Future<String> npcChat({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
    required List<String> sampledWords,
    required int hskLevel,
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
        );

      case AiProvider.ollama:
        return ollamaNpcChat(
          npc: npc,
          playerMessage: playerMessage,
          playerMemory: playerMemory,
          recentMessages: recentMessages,
          sampledWords: sampledWords,
          hskLevel: hskLevel,
        );
    }
  }

  String buildNpcPrompt({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
    required List<String> sampledWords,
    required int hskLevel,
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
      
      플레이어에 대한 전역 기억:
      ${playerMemoryText.isEmpty ? '아직 기억 없음' : playerMemoryText}
      
      
      이 NPC만의 기억:
      $npcMemoryText
      
      최근 대화:
      $recentText
      
      ${getHskPrompt(hskLevel)}
      
        사용자가 이미 아는 단어:
      ${sampledWords.join(', ')}
      
      당신은 중국어로 말합니다.
      위 단어는 참고용입니다.
      대화 내용과 자연스럽게 어울릴 때만 사용하세요.
      억지로 사용하지 마세요.
      
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
    required List<String> sampledWords,
    required int hskLevel,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
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
    required List<String> sampledWords,
    required int hskLevel,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
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
  String cleanJsonText(String text) {
    return text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }


  Future<List<Map<String, String>>> extractMemory({
    required String playerMessage,
    required List<String> allowedTypes,
  }) async {
    final prompt = '''
다음 플레이어 발화에서 장기 기억할 만한 정보를 추출하세요.

허용된 type:
${allowedTypes.join(', ')}

규칙:
- 허용된 type 중 하나에 해당할 때만 추출하세요.
- 기억할 내용이 없으면 [] 만 출력하세요.
- 반드시 JSON만 출력하세요.
- 설명하지 마세요.
- 허용된 type에 해당하지 않으면 저장하지 마세요.
- 질문문, 감탄문은 기억으로 저장하지 마세요.
- 저장할 정보가 없으면 반드시 아래를 출력하세요.
- 플레이어가 자신에 대한 새로운 정보를 제공한 경우에만 추출하세요.
- value는 비어 있으면 안 됩니다.
{"type":"none","value":""}
- 여러 정보가 있으면 여러 객체로 출력하세요.
예시: 

입력: 내 이름은 마야야 난 마라탕이 좋아
출력: [
  {"type":"name","value":"마야"},
  {"type":"preference","value":"마라탕"}
]

입력: 내 이름은 나오야
출력: {"type":"name","value":"나오"}

입력: 내 이름이 뭐야?
출력: []

입력: 안녕
출력: []

입력:
$playerMessage

출력:
''';

    try {
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
      final text = (data['response'] ?? '').trim();

      debugPrint('MEMORY EXTRACT RAW: $text');
      final cleanedText = cleanJsonText(text);
      // final parsed = jsonDecode(cleanedText);
      // 한개 일때만 가능.. 변경
      // final type = parsed['type']?.toString();
      // final value = parsed['value']?.toString().trim();

      final parsed = jsonDecode(cleanedText);

      if (parsed is! List) {
        return  [];
      }

      final memories = <Map<String, String>>[];


      for (final item in parsed) {
        if (item is! Map) continue;

        final type = item['type']?.toString();
        final value = item['value']?.toString().trim();
        // return parsed
        //     .whereType<Map>()
        //     .map((e) {
        //   final type = e['type']?.toString();
        //   final value = e['value']?.toString().trim();
        if (type == null || type == 'none') continue;
        if (value == null || value.isEmpty) continue;
        if (!allowedTypes.contains(type)) continue;
        //
        // if (type == null || type == 'none' || value == null || value.isEmpty) {
        //   return null;
        // }


        memories.add({
          'type': type,
          'value': value,
        });
      }
      return memories;
        // return {
        //   'type': type,
        //   'value': value,
        // };
      //})
      //     .whereType<Map<String, String>>()
      //     .toList();

    } catch (e) {
      debugPrint('기억 추출 오류: $e');
      return [];
    }
  }
}

//   final response = await http.post(
//     Uri.parse('http://localhost:11434/api/generate'),



