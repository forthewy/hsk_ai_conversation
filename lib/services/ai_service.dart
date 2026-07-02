import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:hskchat/models/npc_state.dart';

import '../data/hsk_list.dart';
import '../models/NPCData.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/hsk_data.dart';

enum AiProvider { gemini, ollama }

class AiService {

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


  String buildHskPrompt(HskData hsk) {
    return '''
    사용자는 HSK${hsk.level} 학습자입니다.
    
    가능한 대화 주제:
    ${hsk.topics.map((e) => "- $e").join("\n")}
    
    대화 순서:
    ${hsk.conversationFlow.join(" → ")}
    한 주제에서 1~2번 정도만 대화한 후
    다음 주제로 자연스럽게 넘어갑니다.
    
    모르는 단어 ${hsk.unknownWordLimit}개까지 사용 가능합니다.
    ''';
  }

  String buildStatePrompt(NpcState state) {
    switch (state) {
      case NpcState.greeting:
        return buildGreetingStatePrompt();

      case NpcState.introduction:
        return buildIntroductionStatePrompt();

      case NpcState.quest:
        return buildQuestStatePrompt();

      case NpcState.freeTalk:
        return buildFreeTalkStatePrompt();

      case NpcState.questComplete:
        return buildQuestCompletePrompt();
    }
  }

  String buildGreetingStatePrompt() {
    return "현재 상태는 Greeting입니다. 인사하고 이름을 물어보세요.";
  }
  String buildQuestStatePrompt() {
    return '''현재 상태 : Quest

          당신의 최우선 목표는
          플레이어에게 퀘스트를 전달하는 것입니다.
          
          퀘스트:
          학교에 있는 선생님을 찾아가 인사하세요.
          
          
          플레이어가 인사하더라도
          짧게 인사한 뒤 자연스럽게 퀘스트를 설명하세요.
          
          다른 주제로 대화를 시작하지 마세요.''';
  }
  String buildIntroductionStatePrompt() {
    return '''
    현재 상태: Introduction
    
    목표:
    좋아하는 것을 서로 이야기
    
    규칙:
    - 이름을 다시 묻지 않는다.
    - 간단한 자기소개를 한다.
    - 좋아하는 것 등을 자연스럽게 대화한다.
    ''';
  }

  String buildQuestCompletePrompt() {
    return '''
    현재 상태: QuestComplete
    
    목표:
    플레이어의 퀘스트 완료를 축하한다.
    
    규칙:
    - 완료를 칭찬한다.
    - 보상을 알려준다.
    - 새로운 퀘스트는 주지 않는다.
    ''';
  }

  String buildFreeTalkStatePrompt() {
    return '''
    현재 상태: FreeTalk
    
    목표:
    플레이어와 자유롭게 대화한다.
    
    규칙:
    - 새로운 퀘스트를 시작하지 않는다.
    - 이미 알고 있는 정보는 다시 묻지 않는다.
    - 자연스럽게 대화를 이어간다.
    ''';
  }

  String buildNpcPrompt({
    required NPCData npc,
    required String playerMessage,
    required Map<String, dynamic> playerMemory,
    required List<Map<String, String>> recentMessages,
    required List<String> sampledWords,
    required int hskLevel,
    required NpcState state,
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
    final hsk = hskMap[hskLevel]!;
    if (playerMemory.containsKey("name")) {
      state = NpcState.introduction;
    }
    if (playerMemory.containsKey("preference")) {
      state = NpcState.quest;
    }
    final statePrompt = buildStatePrompt(state);

    final prompt =
        '''
      ${buildNpcProfile(npc)}
      
      ${statePrompt}
      
      플레이어에 대한 전역 기억:
      ${playerMemoryText.isEmpty ? '아직 기억 없음' : playerMemoryText}
      
      
      이 NPC만의 기억:
      $npcMemoryText
      
      최근 대화:
      $recentText
      
       ${buildHskPrompt(hsk)}
      
        사용자가 이미 아는 단어:
      ${sampledWords.join(', ')}
      
      당신은 중국어로 말합니다.
      위 단어는 참고용입니다.
      대화 내용과 자연스럽게 어울릴 때만 사용하세요.
      억지로 사용하지 마세요.
      이미 기억에 있는 정보를 다시 질문하지 마세요.
      플레이어의 한국어 문장을 중국어로 번역하려고 하지 마세요.
      플레이어의 의도만 이해한 후 자연스럽게 대답하세요.
      병음을 출력하지 마세요.
      
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
    required NpcState state,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
        state:state,
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
    required NpcState state,
  }) async {
    try {
      final prompt = buildNpcPrompt(
        npc: npc,
        playerMessage: playerMessage,
        playerMemory: playerMemory,
        recentMessages: recentMessages,
        sampledWords: sampledWords,
        hskLevel: hskLevel,
        state:state,
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
- goal은 사용자가 앞으로 하고 싶은 일만 저장.
예시
- 중국어를 잘하고 싶다.
- 아래는 goal이 아니다.
- 나도 여기 살아.
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
      String text;

      if (provider == AiProvider.gemini) {
        final response = await model.generateContent([
          Content.text(prompt),
        ]);
        text = (response.text ?? '').trim();
      } else {
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
        text = (data['response'] ?? '').trim();
      }

      debugPrint('MEMORY EXTRACT RAW: $text');

      final cleanedText = cleanJsonText(text);
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



String buildNpcProfile(NPCData npc) {
  return '''
당신은 ${npc.name}입니다.

성격:
${npc.personalities.map((e) => "- $e").join("\n")}

가능한 대화 주제:
${npc.topics.map((e) => "- $e").join("\n")}
''';
}
