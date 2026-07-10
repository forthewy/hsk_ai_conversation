import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final pageRange = viewModel.pageRange;
    final startPage = pageRange[0];
    final endPage = pageRange[1];
    final selectedPage = viewModel.selectedPage;

    final overallTotalCount = viewModel.levelWords.length;

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
            // 단어 검색창
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Color(0xFFFFF8EC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xff8B5A2B),
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xffC8A46D),
                            width: 2,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xff8B5A2B),
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xff8B5A2B),
                        ),

                        hintText: "단어 검색",
                      ),
                      controller: wordSearchController,
                      onChanged: viewModel.changeSearchKeyword,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      wordSearchController.clear();
                    },
                    icon: Icon(Icons.close,),
                  ),
                ],
              ),
            ),

            // 사전 종류 (문법.단어.채팅? ETC)
            Expanded(
              child: Stack(
                children: [
                  Row(
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
                            // 아는 단어
                            IconButton(
                              onPressed: () {
                                context.read<WordViewModel>().changeContent(
                                  ContentType.knownWords,
                                );
                              },
                              icon: Icon(Icons.check_circle),
                              iconSize: 30,
                            ),
                            //
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
                          child: viewModel.searchResults.isNotEmpty
                              ? Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "검색 결과 (${viewModel.searchResults.length})",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount:
                                            viewModel.searchResults.length,
                                        itemBuilder: (context, index) {
                                          final word =
                                              viewModel.searchResults[index];

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
                                                    viewModel.getMeaning(word),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
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
                                                      color: const Color(0xFFFFF8EC),
                                                      surfaceTintColor: Colors.transparent,
                                                      onSelected: (value) {
                                                        context
                                                            .read<
                                                              WordViewModel
                                                            >()
                                                            .changeHskLevel(
                                                              value,
                                                            );
                                                      },
                                                      itemBuilder: (context) {
                                                        return List.generate(
                                                          7, (i) {
                                                          final level = i + 1;

                                                          return PopupMenuItem(
                                                            value: level,
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    "HSK $level",
                                                                    style: const TextStyle(
                                                                    ),
                                                                  ),
                                                                ),

                                                                if (viewModel.selectedHskLevel == level)
                                                                  const Icon(
                                                                    Icons.check,
                                                                    size: 18,
                                                                  ),
                                                              ],
                                                            ),
                                                          );
                                                        });
                                                      },

                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            "HSK ${viewModel.selectedHskLevel}",
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    PopupMenuButton<WordFilter>(
                                                      color: const Color(0xFFFFF8EC),
                                                      surfaceTintColor: Colors.transparent,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      onSelected: (value) {
                                                        context
                                                            .read<WordViewModel>().changeFilter(
                                                              value,
                                                            );
                                                      },
                                                      itemBuilder: (context) =>
                                                          const [
                                                            PopupMenuItem(
                                                              value: WordFilter
                                                                  .all,
                                                              child: Text("전체"),
                                                            ),
                                                            PopupMenuItem(
                                                              value: WordFilter
                                                                  .known,
                                                              child: Text("암기"),
                                                            ),
                                                            PopupMenuItem(
                                                              value: WordFilter
                                                                  .unknown,
                                                              child: Text(
                                                                "미암기",
                                                              ),
                                                            ),
                                                          ],
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                              switch (viewModel.selectedFilter) {
                                                            WordFilter.all =>
                                                              "전체",
                                                            WordFilter.known =>
                                                              "암기",
                                                            WordFilter
                                                                .unknown =>
                                                              "미암기",
                                                              },
                                                            style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                                  ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          const Icon(
                                                            Icons.arrow_drop_down,
                                                          ),
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 20,
                                                      ),
                                                  child: Column(
                                                    children: [
                                                      if (viewModel
                                                          .isHeaderExpanded) ...[
                                                        // const Text(
                                                        //   "🐼",
                                                        //   style: TextStyle(fontSize: 60),
                                                        // ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),

                                                        Text(
                                                          "해당 레벨 암기 :  ${viewModel.overallKnownCount} / ${overallTotalCount}",
                                                        ),

                                                        const SizedBox(
                                                          height: 12,
                                                        ),

                                                        LinearProgressIndicator(
                                                          value: viewModel
                                                              .overallProgress,
                                                          backgroundColor: const Color(0xffE5D8C0),

                                                          color: const Color(0xff8B5A2B),

                                                          minHeight: 10,

                                                          borderRadius: BorderRadius.circular(8),
                                                        ),

                                                        const SizedBox(
                                                          height: 12,
                                                        ),

                                                        Text(
                                                          "현재 페이지 암기 : ${viewModel.currentPageKnownCount} / ${viewModel.currentPageTotalCount}",
                                                        ),

                                                        LinearProgressIndicator(
                                                          value: viewModel
                                                              .currentProgress,
                                                          backgroundColor: const Color(0xffE5D8C0),

                                                          color: const Color(0xff8B5A2B),

                                                          minHeight: 10,

                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ],

                                                      Icon(
                                                        viewModel
                                                                .isHeaderExpanded
                                                            ? Icons
                                                                  .keyboard_arrow_up
                                                            : Icons
                                                                  .keyboard_arrow_down,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    // ===== 페이지 =====
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            onPressed: selectedPage > 1
                                                ? () {
                                                    context
                                                        .read<WordViewModel>()
                                                        .prevPage();
                                                  }
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_left,
                                              color: Color(0xff8B5A2B),
                                            ),
                                          ),

                                          for (
                                            int i = startPage;
                                            i <= endPage;
                                            i++
                                          )
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                onTap: () {
                                                  viewModel.changePage(i);
                                                },
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: selectedPage == i
                                                        ? const Color(0xff8B5A2B)
                                                        : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    "$i",
                                                    style: TextStyle(
                                                      color: selectedPage == i
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          IconButton(
                                            onPressed:
                                                selectedPage <
                                                    viewModel.totalPages
                                                ? () {
                                                    context
                                                        .read<WordViewModel>()
                                                        .nextPage();
                                                  }
                                                : null,
                                            icon: const Icon(
                                              Icons.chevron_right,
                                              color: Color(0xff8B5A2B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 8),
                                    // ===== 단어 목록 =====
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: viewModel.words.length,
                                        itemBuilder: (context, index) {
                                          final word = viewModel.words[index];
                                          // 단어 카드
                                          return Card(
                                            color: const Color(0xFFFFFDF7),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                word.simplified,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    word.pinyin,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                  Text(
                                                    viewModel.getMeaning(word),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(
                                                  viewModel.isKnown(word)
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: viewModel.isKnown(word)
                                                      ? const Color(0xff8B5A2B)
                                                      : Colors.grey,
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
                  // 단어 검색 제안
                  if (viewModel.suggestions.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 8,
                      right: 0,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.suggestions.length,
                            itemBuilder: (context, index) {
                              final word = viewModel.suggestions[index];

                              return ListTile(
                                title: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(word.simplified),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        style: TextStyle(color: Colors.grey),
                                        viewModel.getMeaning(word),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  style: TextStyle(color: Colors.redAccent),
                                  "[" + word.pinyin + "]",
                                ),
                                onTap: () {
                                  viewModel.selectSuggestion(word);
                                  wordSearchController.text = word.simplified;
                                },
                              );
                            },
                          ),
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
