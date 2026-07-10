import '../data/hsk_list.dart';
import '../models/hsk_data.dart';
import '../models/npc_data.dart';
import '../models/npc_state.dart';

class NpcPromptBuilder {
  String buildHskPrompt(HskData hsk) {
    return '''
사용자는 HSK${hsk.level} 학습자입니다.
''';
  }

  String buildStatePrompt(NpcState state, Map<String, dynamic> playerMemory) {
    switch (state) {
      case NpcState.introduction:
        return buildIntroductionStatePrompt(playerMemory);
      case NpcState.quest:
        return buildQuestStatePrompt();
      case NpcState.freeTalk:
        return buildFreeTalkStatePrompt();
      case NpcState.questComplete:
        return buildQuestCompletePrompt();
    }
  }

  String buildIntroductionStatePrompt(Map<String, dynamic> playerMemory) {
    if (!playerMemory.containsKey("name")) {
      return "플레이어에게 이름을 물어보세요.";
    }

    if (!playerMemory.containsKey("preference")) {
      return "현재 목표는 좋아하는 것을 묻는 것입니다. 절대로 이름을 묻지 마세요. 이번 응답에서는 좋아하는 것만 물어보세요.";
    }
    return buildQuestStatePrompt();
  }

  String buildQuestStatePrompt() {
    return '''
현재 상태 : Quest
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

다른 주제로 대화를 시작하지 마세요.
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

  String buildRolePrompt(NPCData npc) {
    return '''
    당신은 ${npc.name}입니다.
    
    성격:
    ${npc.personalities.map((e) => "- $e").join("\n")}
    ''';
  }

  String buildMustPrompt() {
    return '''
    당신은 중국어로 말합니다.
    발음을 출력하지 마세요.
    반드시 괄호 안에 한국어 번역을 포함하세요.''';
  }

  String buildProhibitionPrompt() {
    return '''
    
    ''';
  }

  String buildPriorityPrompt() {
    return '''가장 중요한 목표는 현재 상태(State)를 수행하는 것입니다.''';
  }

  String buildMemoryPrompt(NPCData npc, Map<String, dynamic> playerMemory) {
    final npcMemoryText = npc.memories.isEmpty
        ? '아직 기억한 내용 없음'
        : npc.memories.join('\n');

    final playerMemoryText = playerMemory.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    return '''
      플레이어에 대한 전역 기억:
      ${playerMemoryText.isEmpty ? '아직 기억 없음' : playerMemoryText}
      
      이 NPC만의 기억:
      $npcMemoryText
      
      이미 기억한 정보를 다시 질문하지 마세요.
      ''';
  }

  String buildRecentPrompt(List<Map<String, String>> recentMessages) {
    final recentText = recentMessages.isEmpty
        ? '아직 최근 대화 없음'
        : recentMessages.map((m) => '${m['role']}: ${m['content']}').join('\n');
    return '''
      최근 대화:
      $recentText
      
      이미 한 말을 또 하지 마세요
      ''';
  }

  String buildWordPrompt(List<String> sampledWords) {
    return '''
    사용자가 이미 아는 단어:
    ${sampledWords.join(', ')}
    
    위 단어는 참고용입니다.
    대화 내용과 자연스럽게 어울릴 때만 사용하세요.
    억지로 사용하지 마세요.
    ''';
  }

  String buildOutputPrompt() {
    return '''
        출력은 아래와 같은 형식입니다.
        
        잘못된 예
        你叫什么名字？
        
        올바른 예
        你叫什么名字？ (이름이 뭐야?)
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
    final hsk = hskMap[hskLevel]!;

    return '''
    ===== ROLE =====
    ${buildRolePrompt(npc)}
    
    ===== MUST =====
    ${buildMustPrompt()}
    
    ===== PROHIBITION =====
    ${buildProhibitionPrompt()}
    
    ===== STATE =====
    ${buildStatePrompt(state, playerMemory)}
    
    ===== PRIORITY =====
    ${buildPriorityPrompt()}
    
    ===== MEMORY =====
    ${buildMemoryPrompt(npc, playerMemory)}
    

    
    ===== HSK =====
    ${buildHskPrompt(hsk)}
    
    ===== WORDS =====
    ${buildWordPrompt(sampledWords)}
    
    ===== OUTPUT =====
    ${buildOutputPrompt()}
    
    ===== PLAYER =====
    $playerMessage
    
    ===== NPC =====
    ''';
  }
}
//    최근 메세지 내역 삭제
//    ===== RECENT =====
//     ${buildRecentPrompt(recentMessages)}