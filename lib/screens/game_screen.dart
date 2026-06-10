import 'package:flutter/material.dart';

import '../models/NPCData.dart';
import '../models/game_object.dart';
import '../services/ai_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// 플레이어
class Player {
  double x;
  double y;

  Player({required this.x, required this.y});
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();

    objects = [
      GameObject(
        id: 'school_student_object_1',
        type: ObjectType.npc,
        x: 180,
        y: 180,
        name: '학생',
        npcDataId: 'student',
      ),
      GameObject(
        id: 'building_1',
        type: ObjectType.building,
        x: 140,
        y: 40,
        name: '학교',
      ),
    ];
  }

  Map<String, NPCData> npcDatabase = {
    'teacher': NPCData(
      objectId: 'teacher',
      place: PlaceType.school,
      systemPrompt: '''
      당신은 한국어가 유창한 선생님입니다.
      중간중간 쉬운 문장이나 단어는 중국어로 말합니다.
      답변은 2문장 이내로 짧게 합니다.
      ''',
      memories: [],
      name: "선생님",
    ),
    'student': NPCData(
      objectId: 'student',
      place: PlaceType.school,
      systemPrompt: '''
      당신은 한국어가 유창한 학생입니다.
      중간중간 쉬운 문장이나 단어는 중국어로 말합니다.
      답변은 2문장 이내로 짧게 합니다.
      ''',
      memories: [],
      name: "학생",
    ),
  };


  List<GameObject> objects = [];
  GameObject? interactableObject;
  final aiService = AiService();

  final player = Player(x: 100, y: 100);
  final double worldWidth = 400;
  final double worldHeight = 700;
  final double playerSize = 40;
  final dialogController = TextEditingController();
  GameObject? currentNpc;

  // 대화창
  bool isTalking = false;
  String playerText = '';
  String npcText = '';

  void interact() {
    if (interactableObject == null) return;

    switch (interactableObject!.type) {
      case ObjectType.npc:
        startDialog(interactableObject!);
        break;

      case ObjectType.building:
        enterBuilding(interactableObject!);
        break;

      case ObjectType.item:
      case ObjectType.board:
    }
  }

  String getInteractionText() {
    if (interactableObject == null) return '';

    switch (interactableObject!.type) {
      case ObjectType.npc:
        return '${interactableObject!.name}와 대화';

      case ObjectType.building:
        return '${interactableObject!.name} 입장';

      case ObjectType.item:
        return '${interactableObject!.name} 줍기';

      case ObjectType.board:
        return '${interactableObject!.name} 읽기';
    }
  }

  void checkInteractableObject() {
    interactableObject = null;

    for (final obj in objects) {
      final dx = (player.x - obj.x).abs();
      final dy = (player.y - obj.y).abs();

      if (dx < 50 && dy < 50) {
        interactableObject = obj;
        break;
      }
    }

    setState(() {});
  }

  //이동
  void movePlayer(double dx, double dy) {
    setState(() {
      player.x += dx;
      player.y += dy;

      // LEFT
      if (player.x < 0) {
        player.x = 0;
      }

      // TOP
      if (player.y < 0) {
        player.y = 0;
      }

      // RIGHT
      if (player.x > worldWidth - playerSize) {
        player.x = worldWidth - playerSize;
      }

      // BOTTOM
      if (player.y > worldHeight - playerSize) {
        player.y = worldHeight - playerSize;
      }
    });

    checkInteractableObject();
  }

  void startDialog(GameObject npc) {
    setState(() {
      currentNpc = npc;
      isTalking = true;
      npcText = '${npc.name}와 대화 시작';
      //dialogText = '${npc.name}와 대화 시작';
    });
  }

  void enterBuilding(GameObject building) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(building.name),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 120,
                color: Colors.brown,
                child: const Center(child: Text('건물 이미지')),
              ),

              const SizedBox(height: 12),

              const Text('이곳에서 무엇을 할까?'),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('나가기'),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: npcDatabase.values
                  .where((npc) => npc.place == PlaceType.school)
            .map((npc) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    startDialog(GameObject(
                      id: 'school_${npc.objectId}',
                      type: ObjectType.npc,
                      x: 0,
                      y: 0,
                      name: npc.name,
                      npcDataId: npc.objectId,
                    ),);
                  },
                  child: Text(npc.name),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          // 드래그 이동
          onPanUpdate: (details) {
            movePlayer(details.delta.dx, details.delta.dy);
          },
          child: Stack(
            children: [
              // 맵
              buildMap(),
              // 빌딩 , npc
              buildObjects(),
              // 플레이어
              buildPlayer(),
              // 대화창
              if (isTalking) buildDialog(),
              // 기타 ui... 체력... ai 횟수 제한...buildUI(),
              if (interactableObject != null)
                Positioned(
                  bottom: 200,
                  left: 120,
                  child: ElevatedButton(
                    onPressed: interact,
                    child: Text(getInteractionText()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 맵
  Widget buildMap() {
    return Container(color: Colors.green.shade700);
  }

  Widget buildBuildingObject(GameObject obj) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(obj.name),
    );
  }

  Widget buildObjects() {
    return Stack(
      children: objects.map((obj) {
        switch (obj.type) {
          case ObjectType.npc:
            return Positioned(
              left: obj.x,
              top: obj.y,
              child: buildNPCObject(obj),
            );

          case ObjectType.building:
            return Positioned(
              left: obj.x,
              top: obj.y,
              child: buildBuildingObject(obj),
            );

          case ObjectType.item:
            // TODO: Handle this case.
            throw UnimplementedError();
          case ObjectType.board:
            // TODO: Handle this case.
            throw UnimplementedError();
        }
      }).toList(),
    );
  }

  Widget buildNPCObject(GameObject obj) {
    return Container(
      width: 40,
      height: 40,
      color: Colors.yellow,
      child: Text(obj.name),
    );
  }

  // 플레이어
  Widget buildPlayer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),

      left: player.x,
      top: player.y,

      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  @override
  void dispose() {
    dialogController.dispose();
    super.dispose();
  }

  // 대화
  Widget buildDialog() {
    return Align(
      alignment: Alignment.bottomCenter,

      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),

        height: 300,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          children: [
            Text('나: $playerText'),
            const SizedBox(height: 8),
            Text('${currentNpc!.name}: $npcText'),
            //Text(dialogText, style: const TextStyle(fontSize: 20)), // 대화 내용
            Row(
              children: [
                Expanded(child: TextField(controller: dialogController)),
                ElevatedButton(
                  onPressed: () async {
                      final text = dialogController.text.trim();
                      if (text.isEmpty || currentNpc == null) return; // 미입력 or npc 없으면 return
                      final npcDataId = currentNpc!.npcDataId;
                      if (npcDataId == null) {
                        setState(() {
                          npcText = '이 NPC의 데이터가 없습니다.';
                        });
                        return;
                      }
                      final npcData = npcDatabase[npcDataId];;
                      if (npcData == null) {
                        setState(() {
                          npcText = 'NPC 데이터를 찾을 수 없습니다.';
                        });
                        return;
                      }
                      setState(() {
                        playerText = text;
                        npcText = '생각 중...';
                      });

                      final reply = await aiService.npcChat(
                        npc: npcData,
                        playerMessage: text,
                      );
                      setState(() {
                        npcText = reply;
                        dialogController.clear();
                      });
                    },
                  child: const Text('입력'),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isTalking = false;
                      currentNpc = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

