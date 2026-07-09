import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'ai_service.dart';

class MemoryExtractorService {
  final AiProvider provider;
  final GenerativeModel model;

  MemoryExtractorService({
    required this.provider,
    required this.model,
  });

  String cleanJsonText(String text) {
    return text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  Future<List<Map<String, String>>> extractMemory({
    required String playerMessage,
    required List<String> allowedTypes,
  }) async {
    final prompt = '''
너는 입력문 문장에서 key,value 를 추출하는 JSON 추출기이다.

허용된 type:
${allowedTypes.join(', ')}

규칙:
- 허용된 type 중 하나에 해당할 때만 추출하세요.
- 결과는 무조건 JSON List 형식 하나만 출력해라. 다른 설명은 절대 금지한다.
- 정보가 없으면 반드시 [] 만 출력해라.

- name은 플레이어가 자신의 이름을 명시적으로 말한 경우에만 저장하세요.
난 소망이야
→ name

나는 민수야
→ name

내 이름은 리밍이야
→ name

저는 철수입니다
→ name

저는 김영희예요
→ name
난 학생이야
→ []

난 개발자야
→ []

난 배고파
→ []

난 피곤해
→ []

난 행복해
→ []

난 잘 지내
→ []

- 좋아한다고 말한 모든 대상은 preference이다.

예)

난 축구를 좋아해
→ preference

난 사진 찍는게 좋아
→ preference

난 음악 듣는 걸 좋아해
→ preference

난 커피를 좋아해
→ preference
- 여러 정보가 있으면 여러 객체로 출력하세요.
예시:

입력: 내이름은 민수. 난 마라탕을 좋아해.
출력: [
  {"type":"name","value":"민수"},
  {"type":"preference","value":"마라탕"}
]

입력: 내 이름이 뭐야?
출력: []

입력: 난 배고파.
출력:
[]

입력: 난 음악 듣는 걸 좋아해.
출력:
[
  {
    "type":"preference",
    "value":"음악 듣는 것"
  }
]

입력: 내 이름은 리밍이야.
출력:
[
  {
    "type":"name",
    "value":"리밍"
  }
]

입력:
$playerMessage

JSON 출력:
''';

    try {
      String text;

      if (provider == AiProvider.gemini) {
        final response = await model.generateContent([
          Content.text(prompt),
        ]);
        text = (response.text ?? '').trim();
      } else {
        final response = await http.post(
          Uri.parse('http://localhost:11434/api/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'gemma3:4b',
            'prompt': prompt,
            'stream': false,
          }),
        );

        debugPrint(response.body);

        final data = jsonDecode(response.body);
        text = (data['response'] ?? '').trim();
      }

      debugPrint('MEMORY EXTRACT RAW: $text');

      final cleanedText = cleanJsonText(text);
      final parsed = jsonDecode(cleanedText);

      if (parsed is! List) {
        return [];
      }

      final memories = <Map<String, String>>[];

      for (final item in parsed) {
        if (item is! Map) continue;

        final type = item['type']?.toString();
        final value = item['value']?.toString().trim();

        if (type == null || type == 'none') continue;
        if (value == null || value.isEmpty) continue;
        if (!allowedTypes.contains(type)) continue;

        memories.add({
          'type': type,
          'value': value,
        });
      }

      debugPrint(prompt);
      return memories;
    } catch (e) {
      debugPrint('기억 추출 오류: $e');
      return [];
    }
  }
}