import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hskchat/repositories/word_repository.dart';

import '../enums/content_type.dart';
import '../enums/word_filter.dart';
import '../models/word.dart';
import '../models/word_status.dart';

class WordViewModel extends ChangeNotifier {
  final _repository = WordRepository();

  int selectedHskLevel = 1;
  int selectedPage = 1;
  ContentType selectedContent = ContentType.wordBook;

  List<Word> allWords = [];

  Map<String, List<String>> selectedHskLevelMeanings = {};
  WordFilter selectedFilter = WordFilter.all;
  bool isHeaderExpanded = false;

  // 한페이지 당 단어수
  final int pageSize = 30;

  // 초기 실행 메서드
  Future<void> initialize() async {
    await loadWords();
    await loadMeanings();
  }

  // -------로드-------
  // 단어 로드
  Future<void> loadWords() async {
     allWords = await _repository.loadWords();
    notifyListeners();
  }
  // 뜻 로드
  Future<void> loadMeanings() async {
    selectedHskLevelMeanings =
    await _repository.loadMeanings(selectedHskLevel);

    notifyListeners();
  }

  // -------변경-------
  // HSK 레벨 변경
  Future<void> changeHskLevel(int level) async {
    selectedHskLevel = level;
    selectedPage = 1;

    await loadMeanings();

    notifyListeners();
  }

  // 헤더 토글
  void toggleHeader() {
    isHeaderExpanded = !isHeaderExpanded;
    notifyListeners();
  }

  // 다음 페이지
  void nextPage() {
    selectedPage++;
    notifyListeners();
  }

  // 이전 페이지
  void prevPage() {
    if (selectedPage > 1) {
      selectedPage--;
      notifyListeners();
    }
  }

  // 페이지 변경
  void changePage(int page) {
    selectedPage = page;
    notifyListeners();
  }

  // 암기, 미암기 필터 변경
  void changeFilter(WordFilter filter) {
    selectedFilter = filter;
    selectedPage = 1;
    notifyListeners();
  }

  // 콘텐트 변경
  void changeContent(ContentType content) {
    selectedContent = content;
    notifyListeners();
  }

  // 암기/미암기 상태 전환
  Future<void> toggleKnown(Word word) async {
    await _repository.toggleKnown(word);
    notifyListeners();
  }

  // -------getter-------
  // 현재 HSK 전체 단어
  List<Word> get levelWords {
    return allWords.where((e) => e.level == selectedHskLevel).toList();
  }

  // 총 페이지 수 (필터링후 단어 갯수 변경에 따라 변경하기)
  int get totalPages {
    return (levelWords.length / pageSize).ceil();
  }

  // 전체 진행률
  int get overallKnownCount =>
      levelWords.where(_repository.isKnown).length;

  // 전체 암기 갯수
  int get overallTotalCount => levelWords.length;

  // 현재 페이지 진행률
  int get currentPageKnownCount =>
      words.where(_repository.isKnown).length;

  List<Word> get words {
    List<Word> results = [];

    switch (selectedContent) {
      case ContentType.wordBook:
        // 현재 레벨 (필터, 페이지 X)
        results = levelWords;

        // 필터 유
        switch (selectedFilter) {
          case WordFilter.all:
            break;
          case WordFilter.known:
            results = results.where(_repository.isKnown).toList();
            break;
          case WordFilter.unknown:
            results = results.where((word) => !_repository.isKnown(word)).toList();
            break;
        }
        final start = (selectedPage - 1) * pageSize;
        return results.skip(start).take(pageSize).toList();
      case ContentType.knownWords:
        results = allWords.where(
        _repository.isKnown).toList();
        return results;
      case ContentType.favoriteWords:
        results = allWords.where(_repository.isFavorite).toList();
        return results;
    }
  }
  // 단어 상태 (암기.즐겨찾기)
  WordStatus? getStatus(Word word) {
    return _repository.getStatus(word);
  }
}
