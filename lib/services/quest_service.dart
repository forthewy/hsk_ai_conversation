import '../models/quest.dart';
import '../models/quest_progress.dart';

class QuestService {
  QuestProgress updateProgress({
    required Quest quest,
    required QuestProgress progress,
    required String npcId,
    required String playerMessage,
  }) {
    // 이미 완료한 NPC면 무시
    if (progress.completedNpcIds.contains(npcId)) {
      return progress;
    }

    switch (quest.type) {
      case QuestType.greeting:
        // 인사가 아니면 무시
        if (!_isGreeting(playerMessage)) {
          return progress;
        }
        if (npcId != quest.targetNpcId) {
          return progress;
        }
        final completedNpcIds = Set<String>.from(progress.completedNpcIds);
        completedNpcIds.add(npcId);

        return progress.copyWith(
          currentCount: progress.currentCount + 1,
          completedNpcIds: completedNpcIds,
        );
    }
  }

  bool _isGreeting(String text) {
    const greetings = {
      "안녕",
      "안녕하세요",
      "你好",
      "您好",
      "hi",
      "hello",
    };
    final normalized = text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[!?.~\s]'), '');

    return greetings.contains(normalized);
  }

    bool isCompleted({
      required Quest quest,
      required QuestProgress progress,
    }) {
      return progress.currentCount >= quest.targetCount;
    }

  }
  // switch (quest.type) {
  // case QuestType.greeting:
  // // "你好", "您好"가 포함되면 currentCount +1
  //
  // case QuestType.askName:
  // // "你叫什么名字"가 포함되면 +1
  //
  // case QuestType.askPreference:
  // // "你喜欢什么"가 포함되면 +1
  // }