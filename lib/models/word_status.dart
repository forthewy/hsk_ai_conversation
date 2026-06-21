class WordStatus {
  final String simplified;

  bool isKnown;
  bool isFavorite;

  WordStatus({
    required this.simplified,
    this.isKnown = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'simplified': simplified,
    'isKnown': isKnown,
    'isFavorite': isFavorite,
    // seencount .. 이후에 넣을 예정 지금은 무쓸모라 X
  };

  factory WordStatus.fromJson(Map<dynamic, dynamic> json) {
    return WordStatus(
      simplified: json['simplified'],
      isKnown: json['isKnown'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}