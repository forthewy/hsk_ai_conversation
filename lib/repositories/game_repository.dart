import 'package:hive/hive.dart';
import 'package:hskchat/repositories/quest_repository.dart';

import '../models/npc_data.dart';
import '../models/quest_progress.dart';

class GameRepository {
  final npcMemoryBox = Hive.box('npc_memory_box');
  final playerMemoryBox = Hive.box('player_memory_box');

  final QuestRepository questRepository = QuestRepository();

  late QuestProgress progress;

  GameRepository() {
    progress = questRepository.createInitialProgress();
  }

  Map<String, dynamic> getPlayerMemory() {
    return Map<String, dynamic>.from(playerMemoryBox.toMap());
  }

  Future<void> savePlayerMemory({
    required String key,
    required String value,
  }) async {
    await playerMemoryBox.put(key, value);
  }

  Future<void> saveNpcMemory(NPCData npcData) async {
    await npcMemoryBox.put(
      npcData.objectId,
      List<String>.from(npcData.memories),
    );
  }

  Future<void> loadNpcMemories(Map<String, NPCData> npcMap) async {
    for (final npc in npcMap.values) {
      final memories = npcMemoryBox.get(npc.objectId);

      if (memories != null) {
        npc.memories
          ..clear()
          ..addAll(List<String>.from(memories));
      }
    }
  }
}
