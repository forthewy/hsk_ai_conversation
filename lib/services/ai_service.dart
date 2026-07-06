import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:hskchat/models/chat_state.dart';

import '../data/hsk_list.dart';
import '../models/npc_data.dart';
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
    
    ''';
  }

  String buildStatePrompt(NpcState state, Map<String, dynamic> playerMemory) {
    switch (state) {
      case NpcState.introduction:
        return buildIntroductionStatePrompt(playerMemory,);

      case NpcState.quest:
        return buildQuestStatePrompt();

      case NpcState.freeTalk:
        return buildFreeTalkStatePrompt();

      case NpcState.questComplete:
        return buildQuestCompletePrompt();
    }
  }

  String buildQuestStatePrompt() {
    return '''현재 상태 : Quest
          Introduction은 이미 끝났습니다.
          
          절대로 다시
          
          - 자기소개
          - 이름 묻기
          - 취미 묻기
          
          를 하지 마세요.

          반드시 두 문장 안에 퀘스트를 전달하세요.
          
          퀘스트:
          학교에 있는 선생님을 찾아가 인사하세요.
          
          목표: 퀘스트 전달
          
          플레이어가 인사하더라도
          짧게 인사한 뒤 자연스럽게 퀘스트를 설명하세요.
          
          다른 주제로 대화를 시작하지 마세요.''';
  }
  String buildIntroductionStatePrompt(Map<String, dynamic> playerMemory) {
    final todos = <String>[];

    if (!playerMemory.containsKey("name")) {
      todos.add("- 이름 알아내기");
    }

    if (!playerMemory.containsKey("preference")) {
      todos.add("- 좋아하는 것 알아내기");
    }

    final todoText = todos.isEmpty
        ? "- 없음"
        : todos.join("\n");
    return '''
    현재 상태: Introduction
    
    목표:
    ${todos}
    
    규칙:
    - 인사(예: 你好) 하지 않는다.
    - 자연스럽게 대화한다.
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
    if (playerMemory.containsKey("preference") && playerMemory.containsKey("name")) {
      state = NpcState.quest;
    }
    final statePrompt = buildStatePrompt(state, playerMemory);

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
      발음을 출력하지 마세요.
      츌력은 아래와 같은 형식 입니다
      반드시 괄호 안에 한국어 번역을 포함하세요.
      
      잘못된 예
      你好！
      
      올바른 예
      你好！ （안녕!）
      
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
      final prompt = buildNpcPrompt(
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
너는 입력문 문장에서 key,value 를 추출하는 JSON 추출기이다.

허용된 type:
${allowedTypes.join(', ')}

규칙:
- 허용된 type 중 하나에 해당할 때만 추출하세요.
- 결과는 무조건 JSON List 형식 하나만 출력해라. 다른 설명은 절대 금지한다.
- 정보가 없으면 반드시 [] 만 출력해라.

- name은 플레이어가 자신의 이름을 명시적으로 말한 경우에만 저장하세요.
난 소망이야
→ name

나는 민수야
→ name

내 이름은 리밍이야
→ name

저는 철수입니다
→ name

저는 김영희예요
→ name
난 학생이야
→ []

난 개발자야
→ []

난 배고파
→ []

난 피곤해
→ []

난 행복해
→ []

난 잘 지내
→ []

- 좋아한다고 말한 모든 대상은 preference이다.
  
  예)
  
  난 축구를 좋아해
  → preference
  
  난 사진 찍는게 좋아
  → preference

  난 음악 듣는 걸 좋아해
  → preference
  
  난 커피를 좋아해
  → preference
- 여러 정보가 있으면 여러 객체로 출력하세요.
예시: 

입력: 내이름은 민수. 난 마라탕을 좋아해.
출력: [
  {"type":"name","value":"민수"},
  {"type":"preference","value":"마라탕"}
]

입력: 내 이름이 뭐야?
출력: []

입력: 난 배고파.
출력:
[]

입력: 난 음악 듣는 걸 좋아해.
출력:
[
  {
    "type":"preference",
    "value":"음악 듣는 것"
  }
]

입력: 내 이름은 리밍이야.
출력:
[
  {
    "type":"name",
    "value":"리밍"
  }
]

입력:
$playerMessage

JSON 출력:
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
        debugPrint(response.body);
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
        if (type == null || type == 'none') continue;
        if (value == null || value.isEmpty) continue;
        if (!allowedTypes.contains(type)) continue;

        memories.add({
          'type': type,
          'value': value,
        });
      }
      debugPrint(prompt);
      return memories;
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

