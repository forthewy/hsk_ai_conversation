import '../models/hsk_data.dart';

final hskMap = {
  1: HskData(
    level: 1,

    topics: [
      "자기소개",
      "가족",
      "숫자",
      "시간",
      "장소",
      "좋아하는 것",
      "소유",
      "식사",
      "간단한 질문",
    ],

    conversationFlow: [
      "이름",
      "좋아하는 것",
      "학교",
      "친구",
      "식사",
      "다음 약속",
    ],

    unknownWordLimit: 0,
  ),
};