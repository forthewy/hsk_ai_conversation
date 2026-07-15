import '../models/quest.dart';
import '../models/quest_progress.dart';

class QuestRepository {

  final tutorialQuest = Quest(
    id: "greeting_1",
    title: "선생님에게 인사하기",
    description: "선생님에게 인사를 해보세요.",
    type: QuestType.greeting,
    targetCount: 1,
      targetNpcId: "teacher",
  );

  QuestProgress createInitialProgress() {
    return QuestProgress(
      questId: tutorialQuest.id,
      currentCount: 0,
      completedNpcIds: {},
    );
  }
}