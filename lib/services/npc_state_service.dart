import '../models/npc_state.dart';

class NpcStateService {
  NpcState nextState({
    required String npcId,
    required NpcState currentState,
    required Map<String, dynamic> playerMemory,
    required bool questCompleted,
  }) {
    switch (currentState) {
      case NpcState.introduction:
        if (npcId == "student" &&
            playerMemory.containsKey("name") &&
            playerMemory.containsKey("preference")) {
          return NpcState.quest;
        }
        return currentState;

      case NpcState.quest:
        if (questCompleted) {
          return NpcState.questComplete;
        }
        return currentState;
      case NpcState.practice:
        return currentState;

      case NpcState.questComplete:
        return  NpcState.practice;;
    }
  }
}