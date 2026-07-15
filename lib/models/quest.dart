enum QuestType {
  greeting,
  // askName,
  // askPreference,
  // askTime,
  // orderFood,
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int targetCount;
  final String targetNpcId;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.targetNpcId,
  });
}