enum PlaceType {
  school,
  market,
  street,
}

class NPCData {
  final String objectId;
  final PlaceType place;
  final String name;
  final String greeting;

  List<String> memories;

  final String role;
  final List<String> personalities;
  final List<String> topics;

  NPCData({
    required this.objectId,
    required this.place,
    required this.memories,
    required this.name,
    required this.greeting,
    required this.role,
    required this.personalities,
    required this.topics,
  });
}