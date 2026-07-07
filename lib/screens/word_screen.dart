import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hskchat/models/word_status.dart';
import 'package:provider/provider.dart';
import '../enums/content_type.dart';
import '../enums/word_filter.dart';
import '../viewmodels/word_view_model.dart';

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  final wordSearchController = TextEditingController();

  @override
  void dispose() {
    wordSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<WordViewModel>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WordViewModel>();
    final allWords = viewModel.allWords;

    final overallTotalCount = viewModel.levelWords.length;

    int startPage = viewModel.selectedPage - 2;
    int endPage = viewModel.selectedPage + 2;

    if (startPage < 1) {
      endPage += (1 - startPage);
      startPage = 1;
    }

    if (endPage > viewModel.totalPages) {
      startPage -= (endPage - viewModel.totalPages);
      endPage = viewModel.totalPages;

      if (startPage < 1) {
        startPage = 1;
      }
    }
    final currentPageTotalCount = viewModel.words.length;

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
                            context.read<WordViewModel>().changeContent(
                              ContentType.wordBook,
                            );
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
                            context.read<WordViewModel>().changeContent(
                              ContentType.knownWords,
                            );
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
                          if (viewModel.selectedContent ==
                              ContentType.wordBook) ...[
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
                                              context
                                                  .read<WordViewModel>()
                                                  .changeHskLevel(value);
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
                                                  "HSK ${viewModel.selectedHskLevel}",
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
                                              context
                                                  .read<WordViewModel>()
                                                  .changeFilter(value);
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
                                                Text(switch (viewModel
                                                    .selectedFilter) {
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
                                        context
                                            .read<WordViewModel>()
                                            .toggleHeader();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Column(
                                          children: [
                                            if (viewModel.isHeaderExpanded) ...[
                                              // const Text(
                                              //   "🐼",
                                              //   style: TextStyle(fontSize: 60),
                                              // ),
                                              const SizedBox(height: 8),

                                              Text(
                                                "해당 레벨 암기 :  ${viewModel.overallKnownCount} / ${overallTotalCount}",
                                              ),

                                              const SizedBox(height: 12),

                                              LinearProgressIndicator(
                                                value: overallTotalCount == 0
                                                    ? 0
                                                    : viewModel
                                                              .overallKnownCount /
                                                          overallTotalCount,
                                              ),

                                              const SizedBox(height: 12),

                                              Text(
                                                "페이지 암기 : ${viewModel.currentPageKnownCount} / ${currentPageTotalCount}",
                                              ),

                                              LinearProgressIndicator(
                                                value:
                                                    currentPageTotalCount == 0
                                                    ? 0
                                                    : viewModel
                                                              .currentPageKnownCount /
                                                          currentPageTotalCount,
                                              ),
                                            ],

                                            Icon(
                                              viewModel.isHeaderExpanded
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
                                    onPressed: viewModel.selectedPage > 1
                                        ? () {
                                            context
                                                .read<WordViewModel>()
                                                .prevPage();
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
                                            viewModel.changePage(i);
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: viewModel.selectedPage == i
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            "$i",
                                            style: TextStyle(
                                              color: viewModel.selectedPage == i
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  IconButton(
                                    onPressed:
                                        viewModel.selectedPage <
                                            viewModel.totalPages
                                        ? () {
                                            context
                                                .read<WordViewModel>()
                                                .nextPage();
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
                              itemCount: viewModel.words.length,
                              itemBuilder: (context, index) {
                                final word = viewModel.words[index];

                                final status = viewModel.getStatus(word);

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
                                          viewModel
                                                  .selectedHskLevelMeanings[word
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
                                        viewModel.toggleKnown(word);
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
