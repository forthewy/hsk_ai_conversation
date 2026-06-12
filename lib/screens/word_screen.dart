import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word.dart';

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

enum ContentType { wordBook }

class _WordScreenState extends State<WordScreen> {
  List<Word> allWords = [];
  ContentType selectedContent = ContentType.wordBook;
  int selectedHskLevel = 1;
  final wordSearchController = TextEditingController();

  @override
  void dispose() {
    wordSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadWords();
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

  @override
  Widget build(BuildContext context) {
    final words = allWords.where((e) => e.level == selectedHskLevel).toList();

    return Scaffold(
      backgroundColor: Color(0xFFB68B74),
      body: SafeArea(
        child: Column(
          // 배너 파트
          children: [
            Padding(
              padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
              child: Container(height: 200, color: Colors.grey),
            ),
            // 단어 검색창
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFE8E7D4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                controller: wordSearchController,
              ),
            ),
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
                        // 즐겨찾기
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.star),
                          iconSize: 30,
                        ),
                        // HSK 일정
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.calendar_month),
                          iconSize: 30,
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.sticky_note_2_outlined),
                          iconSize: 30,
                        ), //
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.sticky_note_2_outlined),
                          iconSize: 30,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.grey,
                      child: Column(
                        children: [
                          // HSK 선택
                          Wrap(
                            spacing: 8,
                            children: List.generate(7, (index) {
                              final level = index + 1;

                              return ChoiceChip(
                                label: Text('HSK$level'),
                                selected: selectedHskLevel == level,
                                onSelected: (_) {
                                  setState(() {
                                    selectedHskLevel = level;
                                  });
                                },
                              );
                            }),
                          ),

                          const SizedBox(height: 12),

                          // 단어 목록
                          Expanded(
                            child: ListView.builder(
                              itemCount: words.length,
                              itemBuilder: (context, index) {
                                final word = words[index];

                                return Card(
                                  child: ListTile(
                                    onTap: () {},
                                    title: Text(word.simplified),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(word.pinyin),
                                        Text(word.meanings),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
