class Word {
  final String simplified;
  final String pinyin;
  final String meanings;
  final int level;
  Word({
    required this.simplified,
    required this.pinyin,
    required this.meanings,
    required this.level,
  });
  factory Word.fromJson(Map<String, dynamic> json,
      int level) {
    final form = json['forms'][0];

    return Word(
      simplified: json['simplified'],
      pinyin: form['transcriptions']['pinyin'],
      meanings: (form['meanings'] as List).join(', '),
      level: level,
    );
  }
}