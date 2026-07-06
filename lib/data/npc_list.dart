import "package:hskchat/models/npc_data.dart";

final npcMap = <String, NPCData>{
  "student": NPCData(
    objectId: "student",
    name: "小明",
    place: PlaceType.school,
    greeting: "你好！",
    //greeting: "嗨！" 하이
    role: "학교에 다니는 학생",

    personalities: [
      "친근하게 말한다",
      "질문하는 것을 좋아한다",
      "같은 질문을 반복하지 않는다.",
    ],

    topics: [
      "학교",
      "친구",
      "숙제",
    ],

    memories: [],
  ),

  "teacher": NPCData(
    objectId: "teacher",
    name: "선생님",
    place: PlaceType.street,
    greeting: "你好！",
    role: "한국어가 유창한 선생님",

    personalities: [
      "친절하게 설명한다",
      "짧게 답변한다",
    ],

    topics: [
      "학교",
      "공부",
    ],
    memories: [],
  ),
};
