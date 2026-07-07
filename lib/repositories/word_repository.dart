import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/word.dart';
import '../models/word_status.dart';

class WordRepository {
  final _wordStatusBox = Hive.box('word_status_box');

  // -------로드-------
  // 단어 로드
  Future<List<Word>>  loadWords() async {
    final files = [
      'assets/data/1.json',
      'assets/data/2.json',
      'assets/data/3.json',
      'assets/data/4.json',
      'assets/data/5.json',
      'assets/data/6.json',
      'assets/data/7.json',
    ];

    List<Word> loadedWords = [];

    for (int i = 0; i < files.length; i++) {
      final level = i + 1;
      final path = files[i];

      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      loadedWords.addAll(jsonList.map((e) => Word.fromJson(e, level)));
    }
    return loadedWords;
  }

  // 뜻 로드
  Future<Map<String, List<String>>> loadMeanings(int hskLevel) async {
    Map<String, List<String>> selectedHskLevelMeanings = {};
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translations/${hskLevel}_ko.json',
      );

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      selectedHskLevelMeanings = json.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      );
    } catch (_) {
      // 번역이 없으면 원본 뜻 사용
      selectedHskLevelMeanings = {};
    }
    return selectedHskLevelMeanings;
  }

  // 암기
  bool isKnown(Word word) {
    return getStatus(word)?.isKnown ?? false;
  }
  // 즐겨찾기
  bool isFavorite(Word word) {
    return getStatus(word)?.isFavorite ?? false;
  }
  // 상태 확인
  WordStatus? getStatus(Word word) {
    final data = _wordStatusBox.get(word.simplified);

    if (data == null) {
      return null;
    }

    return WordStatus.fromJson(data);
  }
  // 상태 저장
  Future<void> saveStatus(WordStatus status) async {
    await _wordStatusBox.put(
      status.simplified,
      status.toJson(),
    );
  }

  // 암기 전환
  Future<void> toggleKnown(Word word) async{
    final status = getStatus(word) ??
            WordStatus(simplified: word.simplified);

    status.isKnown = !status.isKnown;
    await saveStatus(status);
  }
}
