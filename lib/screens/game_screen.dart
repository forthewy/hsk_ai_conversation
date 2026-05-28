import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
// npc
class NPC {

  final String id;

  double x;
  double y;

  final String dialog;

  NPC({
    required this.id,
    required this.x,
    required this.y,
    required this.dialog,
  });
}

class Building {

  final String id;

  final double x;
  final double y;
  // final string image; 건물 이미지는 이후 추가

  Building({
    required this.id,
    required this.x,
    required this.y,
  });
}
class _GameScreenState extends State<GameScreen> {
  final player = Player(x: 100, y:100);
  final double worldWidth = 400;
  final double worldHeight = 700;
  final double playerSize = 40;
  NPC? currentNPC;
  final List<NPC> npcs = [

    NPC(
      id: 'npc_1',
      x: 180,
      y: 180,
      dialog: '안녕!',
    ),
  ];
  final List<Building> buildings = [

    Building(
      id: 'top',
      x: 140,
      y: 40,
    ),

    Building(
      id: 'left',
      x: 20,
      y: 250,
    ),
  ];

  // 대화창
  bool showDialog = false;
  String dialogText = '';

  // npc
  final double npcX = 180;
  final double npcY = 180;

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

    checkNPCDistance();
  }

  //npc 거리 확인. 대화 시작
  void checkNPCDistance() {

    currentNPC = null;

    for (final npc in npcs) {

      final dx = (player.x - npc.x).abs();
      final dy = (player.y - npc.y).abs();

      if (dx < 50 && dy < 50) {

        currentNPC = npc;

        break;
      }
    }
    if (currentNPC != null)

      Positioned(
        bottom: 180,
        left: 120,

        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black54,

          child: const Text(
            '대화하기',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    // setState(() {
    //
    //   if (currentNPC != null) {
    //
    //     showDialog = true;
    //     dialogText = currentNPC!.dialog;
    //
    //   } else {
    //
    //     showDialog = false;
    //   }
    // });
  }

  void startDialog(NPC npc) {

    setState(() {

      showDialog = true;
      dialogText = npc.dialog;
    });
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
              // 빌딩
              buildBuildings(),
              // npc
              buildNPC(),
              // 플레이어
              buildPlayer(),
              // 대화창
              if (showDialog) buildDialog(),
              // 기타 ui... 체력... ai 횟수 제한...buildUI(),
              Positioned.fill(
                child: Column(
                  children: [

                    Expanded(
                      child: Center(
                        child: Container(
                          width: 80,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          height: 80,
                          color: Colors.brown,
                        ),
                      ),
                    ),
                  ],
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

    return Container(

      color: Colors.green.shade700,

      // child: Center(
      //
      //   child: Container(
      //     width: 180,
      //     height: 180,
      //     color: Colors.brown.shade400,
      //   ),
      // ),
    );
  }

  // 빌딩
  Widget buildBuildings() {

    return Stack(

      children: buildings.map((building) {

        return Positioned(

          left: building.x,
          top: building.y,

          child: buildBuilding(),
        );

      }).toList(),
    );
  }


  Widget buildBuilding() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.brown,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // npc
  Widget buildNPC() {

    return Stack(

      children: npcs.map((npc) {

        return Positioned(

          left: npc.x,
          top: npc.y,

          child: Container(
            width: 40,
            height: 40,
            color: Colors.yellow,
            child:GestureDetector(
              onTap: () {

                startDialog(npc);
              },
            ),
          ),
        );

      }).toList(),
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
