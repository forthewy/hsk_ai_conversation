enum ObjectType {
  npc,
  building,
  item,
  board,
}

class GameObject {
  final String id;
  final ObjectType type;
  final double x;
  final double y;
  final String name;

  final String? npcDataId; // NPC일 때만 사용

  GameObject({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.name,
    this.npcDataId,
  });
}