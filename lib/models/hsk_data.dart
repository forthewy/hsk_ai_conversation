class HskData {
  final int level;
  final List<String> topics;
  final List<String> conversationFlow;
  final int unknownWordLimit;

  const HskData({
    required this.level,
    required this.topics,
    required this.conversationFlow,
    required this.unknownWordLimit,
  });
}