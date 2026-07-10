import '../models/npc_state.dart';

class NpcStateService {
  NpcState nextState({
    required NpcState currentState,
    required Map<String, dynamic> playerMemory,
  }) {
    switch (currentState) {
      case NpcState.introduction:
        if (playerMemory.containsKey("name") &&
            playerMemory.containsKey("preference")) {
          return NpcState.quest;
        }
        return currentState;

      case NpcState.quest:
        return currentState;

      case NpcState.freeTalk:
        return currentState;

      case NpcState.questComplete:
        return currentState;
    }
  }
}