import 'package:hive/hive.dart';

class ConversationRepository {
  final npcMemoryBox = Hive.box('npc_memory_box');

  Future<void> addRecentMessage({
    required String npcId,
    required String role,
    required String content,
    int maxRecentMessages = 20,
  }) async {
    final key = 'recent_$npcId';

    final oldMessages = npcMemoryBox.get(key, defaultValue: []);

    final messages = List<Map<String, String>>.from(
      oldMessages.map((e) => Map<String, String>.from(e)),
    );

    messages.add({'role': role, 'content': content});

    if (messages.length > maxRecentMessages) {
      messages.removeRange(0, messages.length - maxRecentMessages);
    }

    await npcMemoryBox.put(key, messages);
  }

  List<Map<String, String>> getRecentMessages(String npcId) {
    final raw = npcMemoryBox.get('recent_$npcId', defaultValue: []);

    return List<Map<String, String>>.from(
      raw.map((e) => Map<String, String>.from(e)),
    );
  }
}
