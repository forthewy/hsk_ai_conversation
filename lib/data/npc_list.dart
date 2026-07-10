import "package:hskchat/models/npc_data.dart";

final npcMap = <String, NPCData>{
  "student": NPCData(
    objectId: "student",
    name: "小明",
    place: PlaceType.school,
    greeting: "你好！ (안녕!)",
    //greeting: "嗨！" 하이
    role: "학교에 다니는 학생",

    personalities: [
      "친근하게 말한다",
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
    name: "王老师",
    place: PlaceType.school,
    greeting: "你好！",
    role: "학교 선생님",

    personalities: [
      "친절하다",
    ],

    topics: [
      "학교",
      "공부",
    ],
    memories: [],
  ),
};
