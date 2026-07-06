import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hskchat/models/word_status.dart';
import '../models/word.dart';

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

// 단어장 타입
enum ContentType { wordBook, knownWords, favoriteWords }

// 단어 필터링
enum WordFilter { all, known, unknown }

class _WordScreenState extends State<WordScreen> {
  WordFilter selectedFilter = WordFilter.all;
  List<Word> allWords = [];
  ContentType selectedContent = ContentType.wordBook;
  int selectedHskLevel = 1;
  final wordSearchController = TextEditingController();
  final wordStatusBox = Hive.box('word_status_box');
  int selectedPage = 1;
  bool isHeaderExpanded = false;
  Map<String, List<String>> selectedHskLevelMeanings = {};

  @override
  void dispose() {
    wordSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadWords();
    loadMeanings();
  }

  Future<void> loadWords() async {
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

    setState(() {
      allWords = loadedWords;
    });
  }

  Future<void> loadMeanings() async {
    final jsonString = await rootBundle.loadString(
      'assets/translations/${selectedHskLevel}_ko.json',
    );

    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    selectedHskLevelMeanings = json.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    //final words = allWords.where((e) => e.level == selectedHskLevel).toList();
    List<Word> words = [];
    switch (selectedContent) {
      case ContentType.wordBook:
        words = allWords.where((e) => e.level == selectedHskLevel).toList();
        break;

      case ContentType.knownWords:
        words = allWords.where((word) {
          final data = wordStatusBox.get(word.simplified);

          if (data == null) {
            return false;
          }

          return WordStatus.fromJson(data).isKnown;
        }).toList();
        break;

      case ContentType.favoriteWords:
        words = allWords.where((word) {
          final data = wordStatusBox.get(word.simplified);

          if (data == null) {
            return false;
          }

          return WordStatus.fromJson(data).isFavorite;
        }).toList();
        break;
    }

    const pageSize = 30;

    // 현재 HSK 전체 단어
    final levelWords = allWords
        .where((e) => e.level == selectedHskLevel)
        .toList();

    final totalPages = (levelWords.length / pageSize).ceil();

    // 전체 진행률
    final overallKnownCount = levelWords.where((word) {
      final data = wordStatusBox.get(word.simplified);
      if (data == null) return false;
      return WordStatus.fromJson(data).isKnown;
    }).length;

    final overallTotalCount = levelWords.length;

    if (selectedContent == ContentType.wordBook) {
      final start = (selectedPage - 1) * pageSize;
      List<Word> filteredWords = levelWords;

      switch (selectedFilter) {
        case WordFilter.all:
          break;

        case WordFilter.known:
          filteredWords = levelWords.where((word) {
            final data = wordStatusBox.get(word.simplified);
            return data != null && WordStatus.fromJson(data).isKnown;
          }).toList();
          break;

        case WordFilter.unknown:
          filteredWords = levelWords.where((word) {
            final data = wordStatusBox.get(word.simplified);
            return data == null || !WordStatus.fromJson(data).isKnown;
          }).toList();
          break;
      }
      words = filteredWords.skip(start).take(pageSize).toList();
    }

    // 현재 페이지 진행률
    // (아직 페이지 기능이 없으므로 words 사용)
    final currentPageKnownCount = words.where((word) {
      final data = wordStatusBox.get(word.simplified);
      if (data == null) return false;
      return WordStatus.fromJson(data).isKnown;
    }).length;
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
    final currentPageTotalCount = words.length;

    return Scaffold(
      backgroundColor: Color(0xFFB68B74),
      body: SafeArea(
        child: Column(
          children: [
            // 배너 파트
            // Padding(
            //   padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
            //   child: Container(height: 200, color: Colors.grey),
            // ),
            // // 단어 검색창
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: TextField(
            //     decoration: InputDecoration(
            //       filled: true,
            //       fillColor: Color(0xFFFFF8EC),
            //       contentPadding: const EdgeInsets.symmetric(
            //         horizontal: 24,
            //         vertical: 20,
            //       ),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(24),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //     controller: wordSearchController,
            //   ),
            // ),
            // 사전 종류 (문법.단어.채팅? ETC)
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 단어장 (인기 단어장, 학습회화 등등)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedContent = ContentType.wordBook;
                            });
                          },
                          icon: Icon(Icons.sticky_note_2_outlined),
                          iconSize: 30,
                        ),
                        // // 즐겨찾기
                        // IconButton(
                        //   onPressed: () {
                        //     setState(() {
                        //       selectedContent = ContentType.favoriteWords;
                        //     });
                        //   },
                        //   icon: Icon(Icons.star),
                        //   iconSize: 30,
                        // ),
                        // 아는 단어
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedContent = ContentType.knownWords;
                            });
                          },
                          icon: Icon(Icons.check_circle),
                          iconSize: 30,
                        ), //
                        // // HSK 일정
                        // IconButton(
                        //   onPressed: () {},
                        //   icon: Icon(Icons.calendar_month),
                        //   iconSize: 30,
                        // ),
                        // IconButton(
                        //   onPressed: () {},
                        //   icon: Icon(Icons.sticky_note_2_outlined),
                        //   iconSize: 30,
                        // ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF2E8D8),
                      child: Column(
                        children: [
                          // ===== 상단 카드 =====
                          if (selectedContent == ContentType.wordBook) ...[
                            Card(
                              color: const Color(0xFFFFFDF7),
                              margin: const EdgeInsets.all(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // ===== HSK 선택 =====
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          PopupMenuButton<int>(
                                            onSelected: (value) {
                                              setState(() {
                                                selectedHskLevel = value;
                                                selectedPage = 1;
                                              });
                                            },
                                            itemBuilder: (context) {
                                              return List.generate(
                                                7,
                                                (i) => PopupMenuItem(
                                                  value: i + 1,
                                                  child: Text("HSK ${i + 1}"),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "HSK $selectedHskLevel",
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_drop_down,
                                                ),
                                                const Text("레벨 선택"),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          PopupMenuButton<WordFilter>(
                                            onSelected: (value) {
                                              setState(() {
                                                selectedFilter = value;
                                                selectedPage = 1;
                                              });
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: WordFilter.all,
                                                child: Text("전체"),
                                              ),
                                              PopupMenuItem(
                                                value: WordFilter.known,
                                                child: Text("암기"),
                                              ),
                                              PopupMenuItem(
                                                value: WordFilter.unknown,
                                                child: Text("미암기"),
                                              ),
                                            ],
                                            child: Row(
                                              children: [
                                                Text(switch (selectedFilter) {
                                                  WordFilter.all => "전체",
                                                  WordFilter.known => "암기",
                                                  WordFilter.unknown => "미암기",
                                                }),
                                                const Icon(
                                                  Icons.filter_alt_sharp,
                                                ),
                                                const Text(" 필터"),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ===== 접기/펼치기 영역 =====
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          isHeaderExpanded = !isHeaderExpanded;
                                        });
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Column(
                                          children: [
                                            if (isHeaderExpanded) ...[
                                              // const Text(
                                              //   "🐼",
                                              //   style: TextStyle(fontSize: 60),
                                              // ),

                                              const SizedBox(height: 8),

                                              Text(
                                                "해당 레벨 암기 :  $overallKnownCount / $overallTotalCount",
                                              ),

                                              const SizedBox(height: 12),

                                              LinearProgressIndicator(
                                                value: overallTotalCount == 0
                                                    ? 0
                                                    : overallKnownCount /
                                                          overallTotalCount,
                                              ),

                                              const SizedBox(height: 12),

                                              Text(
                                                "페이지 암기 : $currentPageKnownCount / $currentPageTotalCount",
                                              ),

                                              LinearProgressIndicator(
                                                value:
                                                    currentPageTotalCount == 0
                                                    ? 0
                                                    : currentPageKnownCount /
                                                          currentPageTotalCount,
                                              ),
                                            ],

                                            Icon(
                                              isHeaderExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ===== 페이지 =====
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: selectedPage > 1
                                        ? () {
                                            setState(() {
                                              selectedPage--;
                                            });
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),

                                  for (int i = startPage; i <= endPage; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          setState(() {
                                            selectedPage = i;
                                          });
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: selectedPage == i
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            "$i",
                                            style: TextStyle(
                                              color: selectedPage == i
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  IconButton(
                                    onPressed: selectedPage < totalPages
                                        ? () {
                                            setState(() {
                                              selectedPage++;
                                            });
                                          }
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                          // ===== 단어 목록 =====
                          Expanded(
                            child: ListView.builder(
                              itemCount: words.length,
                              itemBuilder: (context, index) {
                                final word = words[index];

                                final statusData = wordStatusBox.get(
                                  word.simplified,
                                );

                                final status = statusData != null
                                    ? WordStatus.fromJson(statusData)
                                    : WordStatus(simplified: word.simplified);

                                return Card(
                                  color: const Color(0xFFFFFDF7),
                                  child: ListTile(
                                    title: Text(word.simplified),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(word.pinyin),
                                        Text(
                                          selectedHskLevelMeanings[word
                                                      .simplified]
                                                  ?.join(", ") ??
                                              word.meanings,
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        status.isKnown
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                      ),
                                      onPressed: () async {
                                        status.isKnown = !status.isKnown;

                                        await wordStatusBox.put(
                                          status.simplified,
                                          status.toJson(),
                                        );

                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
