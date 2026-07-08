import 'package:flutter/material.dart';
import 'package:hskchat/repositories/word_repository.dart';

import '../enums/content_type.dart';
import '../enums/word_filter.dart';
import '../models/word.dart';
import '../models/word_status.dart';

class WordViewModel extends ChangeNotifier {
  final _repository = WordRepository();

  // -------변수-------
  // 검색
  String searchKeyword = '';
  List<Word> suggestions = [];
  List<Word> searchResults = [];

  int selectedHskLevel = 1;
  int selectedPage = 1;

  ContentType selectedContent = ContentType.wordBook;

  List<Word> allWords = [];

  Map<String, List<String>> selectedHskLevelMeanings = {};
  WordFilter selectedFilter = WordFilter.all;
  bool isHeaderExpanded = false;

  bool isKnown(Word word) {
    return _repository.isKnown(word);
  }

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
    selectedHskLevelMeanings = await _repository.loadMeanings(selectedHskLevel);

    notifyListeners();
  }

  // -------변경-------
  // HSK 레벨 변경
  Future<void> changeHskLevel(int level) async {
    selectedHskLevel = level;
    selectedPage = 1;

    await loadMeanings();
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
    clearSearch();
    notifyListeners();
  }

  // 암기/미암기 상태 전환
  Future<void> toggleKnown(Word word) async {
    await _repository.toggleKnown(word);
    notifyListeners();
  }

  // 검색
  void changeSearchKeyword(String keyword) {
    searchKeyword = keyword;

    if (keyword.isEmpty) {
      clearSearch();
      return;
    } else {
      final lowerKeyword = keyword.toLowerCase();
      suggestions = allWords.where((word) {
        return word.simplified.contains(keyword) ||
            word.pinyin.toLowerCase().contains(lowerKeyword) ||
            getMeaning(word).toLowerCase().contains(lowerKeyword) ||
            word.meanings.toLowerCase().contains(lowerKeyword);
      }).toList();
    }

    notifyListeners();
  }

  // 검색 보기 중 선택
  void selectSuggestion(Word word) {
    searchKeyword = word.simplified;
    suggestions = [];
    searchResults = [word];

    notifyListeners();
  }

  // 검색 결과
  void search() {
    searchResults = allWords.where(_matchSearch).toList();
    suggestions = [];

    notifyListeners();
  }
  // 검색 취소
  void clearSearch() {
    searchKeyword = "";
    suggestions = [];
    searchResults = [];

    notifyListeners();
  }

  // 검색 결과
  bool _matchSearch(Word word) {
    final keyword = searchKeyword.toLowerCase();
    final meaning = getMeaning(word).toLowerCase();

    return word.simplified.contains(searchKeyword) ||
        word.pinyin.toLowerCase().contains(keyword) ||
        meaning.contains(keyword);
  }

  // -------getter-------
  // 현재 HSK 전체 단어
  List<Word> get levelWords {
    return allWords.where((e) => e.level == selectedHskLevel).toList();
  }

  // 총 페이지 수 (필터링후 단어 갯수 변경에 따라 변경하기)
  int get totalPages {
    return (displayWords.length / pageSize).ceil();
  }

  // 보여지는 페이지 처음~끝
  List<int> get pageRange {
    int startPage = selectedPage - 2;
    int endPage = selectedPage + 2;

    if (startPage < 1) {
      endPage += (1 - startPage);
      startPage = 1;
    }

    if (endPage > totalPages) {
      startPage -= (endPage - totalPages);
      endPage = totalPages;

      if (startPage < 1) {
        startPage = 1;
      }
    }

    return [startPage, endPage];
  }

  // 전체 진행률
  int get overallKnownCount => levelWords.where(_repository.isKnown).length;

  // 전체 암기 갯수
  int get overallTotalCount => levelWords.length;

  // 현재 페이지 단어 갯수
  int get currentPageTotalCount => words.length;

  // 현재 페이지 진행률
  int get currentPageKnownCount => words.where(_repository.isKnown).length;

  // 페이징
  List<Word> get words {
    final start = (selectedPage - 1) * pageSize;

    return displayWords.skip(start).take(pageSize).toList();
  }

  // 보여줄 단어들
  List<Word> get displayWords {
    List<Word> results = [];

    switch (selectedContent) {
      case ContentType.wordBook:
        results = levelWords;
        results = applyFilter(results);
        break;
      case ContentType.knownWords:
        results = allWords.where(_repository.isKnown).toList();
        return results;
    }
    return results;
  }

  List<Word> applyFilter(List<Word> words) {
    switch (selectedFilter) {
      case WordFilter.all:
        return words;
      case WordFilter.known:
        return words.where(_repository.isKnown).toList();
      case WordFilter.unknown:
        return words.where((w) => !_repository.isKnown(w)).toList();
    }
  }

  // 단어 상태 (암기.즐겨찾기)
  WordStatus? getStatus(Word word) {
    return _repository.getStatus(word);
  }

  // 단어장 단어 뜻 연결
  String getMeaning(Word word) {
    return selectedHskLevelMeanings[word.simplified]?.join(", ") ??
        word.meanings;
  }

  double get overallProgress {
    return overallTotalCount == 0 ? 0 : overallKnownCount / overallTotalCount;
  }

  double get currentProgress {
    return currentPageTotalCount == 0
        ? 0
        : currentPageKnownCount / currentPageTotalCount;
  }
}
