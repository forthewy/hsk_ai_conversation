import 'dart:convert';
import 'dart:io';

Future<void> main() async {

  final text = File('assets/data/1.json').readAsStringSync();
  final data = jsonDecode(text);
  final Map<String, List<String>> wordMeaningList = {};

  for (final word in data) {
    List<String> meaningList = [];
    final form = word["forms"][0];

    for (final meaning in form["meanings"]) {
      meaningList.add(meaning);
    }
    wordMeaningList[word["simplified"]] = meaningList;
  }

  final json = jsonEncode(wordMeaningList);

  File("1_beforeTranslate.json").writeAsStringSync(json);
}

Future<void> loadJson() async {

}