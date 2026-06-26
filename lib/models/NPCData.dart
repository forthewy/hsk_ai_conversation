enum PlaceType {
  school,
  market,
  street,
}

class NPCData {
  final String objectId;
  final String systemPrompt;
  final PlaceType place;
  final String name;
  final String greeting;

  List<String> memories;

  NPCData({
    required this.objectId,
    required this.place,
    required this.systemPrompt,
    required this.memories,
    required this.name,
    required this.greeting,
  });
}