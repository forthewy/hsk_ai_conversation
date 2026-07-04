class HskData {
  final int level;
  final List<String> topics;
  final int unknownWordLimit;
  // 문법. 문형. 게임스크린에서 미사용
  final List<String> grammarPatterns;
  final List<String> sentencePatterns;

  const HskData({
    required this.level,
    required this.topics,
    required this.unknownWordLimit,
    required this.grammarPatterns,
    required this.sentencePatterns,
  });
}
