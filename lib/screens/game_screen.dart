import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/game_object.dart';

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
        id: 'npc_1',
        type: ObjectType.npc,
        x: 180,
        y: 180,
        name: '여행자',
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

  List<GameObject> objects = [];
  GameObject? interactableObject;

  final player = Player(x: 100, y: 100);
  final double worldWidth = 400;
  final double worldHeight = 700;
  final double playerSize = 40;

  // 대화창
  bool showDialog = false;
  String dialogText = '';

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
      showDialog = true;
      dialogText = '${npc.name}와 대화 시작';
    });
  }

  void enterBuilding(GameObject building) {
    print('${building.name} 입장');
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
              if (showDialog) buildDialog(),
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

  Widget buildBuildingObject() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(12),
      ),
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
              child: buildBuildingObject(),
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
    return Container(width: 40, height: 40, color: Colors.yellow);
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

  // 대화
  Widget buildDialog() {
    return Align(
      alignment: Alignment.bottomCenter,

      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),

        height: 140,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Text(dialogText, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
