import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../data/npc_list.dart';
import '../models/game_object.dart';
import '../models/npc_data.dart';
import '../models/word_status.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/game_repository.dart';
import '../services/ai_service.dart';
import '../services/conversation_service.dart';
import '../services/game_service.dart';
import '../services/memory_extractor_service.dart';
import '../viewmodels/game_view_model.dart';
import '../models/player.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

const maxRecentMessages = 20;

class _GameScreenState extends State<GameScreen> {
  final viewModel = GameViewModel();

  late final MemoryExtractorService _memoryExtractor;
  late final ConversationRepository conversationRepository;
  late final ConversationService conversationService;
  late final GameService gameService;

  @override
  void initState() {
    super.initState();
    viewModel.addListener(() {
      setState(() {});
    });
    knownWords = getKnownWords();
    _memoryExtractor = MemoryExtractorService(
      provider: aiService.provider,
      model: aiService.model,
    );
    gameRepository = GameRepository();
    conversationRepository = ConversationRepository();
    gameRepository.loadNpcMemories(npcMap);
    objects = [
      GameObject(
        id: 'building_1',
        type: ObjectType.building,
        x: 140,
        y: 40,
        name: '학교',
      ),
    ];
    conversationService = ConversationService(
      aiService: aiService,
      gameRepository: gameRepository,
      conversationRepository: conversationRepository,
      memoryExtractor: _memoryExtractor,
    );
    gameService = GameService();
  }

  Future<void> sendNpcMessage() async {
    final text = dialogController.text.trim();

    if (text.isEmpty || !viewModel.hasCurrentNpc) return;

    final npcData = npcMap[viewModel.currentNpc!.npcDataId]!;
    final sampledWords = conversationService.sampleKnownWords(knownWords);
    viewModel.setNpcLoading(true);

    try {
      final result = await conversationService.sendMessage(
        npcData: npcData,
        playerMessage: text,
        sampledWords: sampledWords,
        hskLevel: viewModel.playerHskLevel,
      );
      viewModel.addMessage(role: 'player', content: text);
      viewModel.addMessage(role: 'npc', content: "${result.reply}\n(${result.translation})");
      dialogController.clear();
    } finally {
      viewModel.setNpcLoading(false);
    }
  }

  List<GameObject> objects = [];
  GameObject? interactableObject;
  final aiService = AiService();
  final player = Player(x: 100, y: 100);
  final double worldWidth = 400;
  final double worldHeight = 700;
  final double playerSize = 40;
  final dialogController = TextEditingController();
  List<String> knownWords = [];
  List<String> sampledWords = [];
  final wordStatusBox = Hive.box('word_status_box');
  late final GameRepository gameRepository;

  // 아는 단어
  List<String> getKnownWords() {
    final result = <String>[];

    for (final data in wordStatusBox.values) {
      final status = WordStatus.fromJson(data);

      if (status.isKnown) {
        result.add(status.simplified);
      }
    }

    return result;
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

  void interact() {
    if (interactableObject == null) return;

    switch (interactableObject!.type) {
      case ObjectType.npc:
        viewModel.startDialog(interactableObject!);
        break;

      case ObjectType.building:
        enterBuilding(interactableObject!);
        break;

      case ObjectType.item:
        break;

      case ObjectType.board:
        break;
    }
  }

  void enterBuilding(GameObject building) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7EED8),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Center(
            child: Text(
              "${building.name}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff5A3416),
                fontSize: 20,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xffD8C29D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('건물 이미지')),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "누구와 대화할까요?",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5A3416),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: npcMap.values
                    .where((npc) => npc.place == PlaceType.school)
                    .map((npc) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff8B5A2B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          viewModel.startDialog(
                            GameObject(
                              id: 'school_${npc.objectId}',
                              type: ObjectType.npc,
                              x: 0,
                              y: 0,
                              name: npc.name,
                              npcDataId: npc.objectId,
                            ),
                          );
                        },
                        //  대화 버튼
                        child: Text("▶ ${npc.name} (${npc.role})"),
                      );
                    })
                    .toList(),
              ),
            ),
            Divider(),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xffB87A4B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('나가기'),
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
            setState(() {
              gameService.movePlayer(
                player: player,
                dx: details.delta.dx,
                dy: details.delta.dy,
                worldWidth: worldWidth,
                worldHeight: worldHeight,
                playerSize: playerSize,
              );

              interactableObject = gameService.findInteractableObject(
                player,
                objects,
              );
            });
          },
          child: Stack(
            children: [
              // 맵
              buildMap(),
              // 빌딩 , npc
              buildObjects(),
              // 플레이어
              buildPlayer(),
              Positioned(
                top: 20,
                right: 20,
                child: PopupMenuButton<int>(
                  color: Color(0xFFF7EED8),
                  shape: const RoundedRectangleBorder(
                    side: BorderSide(
                      color: Color(0xff8B5A2B),
                      width: 1.0, // 선 두께 (생략 가능)
                    ),
                  ),
                  onSelected: (value) {
                    viewModel.setHskLevel(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 1, child: Text('HSK1')),
                    const PopupMenuItem(
                      value: 2,
                      child: Text('HSK2 🔒 Coming Soon'),
                      enabled: false,
                    ),
                    const PopupMenuItem(
                      value: 3,
                      child: Text('HSK3 🔒 Coming Soon'),
                      enabled: false,
                    ),
                    const PopupMenuItem(
                      value: 4,
                      child: Text('HSK4 🔒 Coming Soon'),
                      enabled: false,
                    ),
                    const PopupMenuItem(
                      value: 5,
                      child: Text('HSK5 🔒 Coming Soon'),
                      enabled: false,
                    ),
                    const PopupMenuItem(
                      value: 6,
                      child: Text('HSK6 🔒 Coming Soon'),
                      enabled: false,
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EED8),
                      border: Border.all(
                        color: const Color(0xff8B5A2B),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'HSK${viewModel.playerHskLevel} ▼',
                      style: const TextStyle(
                        color: Color(0xff5A3416),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // 대화창
              if (viewModel.isTalking) buildDialog(),
              // 기타 ui... 체력... ai 횟수 제한...buildUI(),
              if (interactableObject != null && !viewModel.isInteracting)
                Positioned(
                  bottom: 200,
                  left: 120,
                  child: ElevatedButton(
                    onPressed: interact,
                    child: Text(getInteractionText()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff8B5A2B),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
    return Container(color: Color(0xff88B56A));
  }

  Widget buildBuildingObject(GameObject obj) {
    return Container(
      width: 100,
      height: 100,
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
    viewModel.dispose();
    super.dispose();
  }

  // 대화창 위젯
  Widget buildDialog() {
    final npcData = npcMap[viewModel.currentNpc!.npcDataId]!;
    final lastMessages = viewModel.lastMessages;
    return Align(
      alignment: Alignment.bottomCenter,

      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),

        height: 300,

        decoration: BoxDecoration(
          color: Color(0xFFF7EED8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xff8B5A2B), width: 2),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Text(
                  "【${viewModel.currentNpc!.name}】",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {
                    viewModel.closeDialog();
                    dialogController.clear();
                  },
                  color: Color(0xffB87A4B),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            Divider(color: Color(0xff8B5A2B), thickness: 1.5),
            // 대화
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastMessages.isEmpty)
                  Text('${viewModel.currentNpc!.name}: ${npcData.greeting}')
                else
                  ...lastMessages.map((message) {
                    final speaker = message['role'] == 'player'
                        ? '나'
                        : viewModel.currentNpc!.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('$speaker: ${message['content']}'),
                    );
                  }),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dialogController,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요",
                      filled: true,
                      fillColor: Color(0xFFFFFAF2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xffC8A46D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Color(0xff8B5A2B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff8B5A2B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: viewModel.isNpcLoading ? null : sendNpcMessage,
                    child: Text(viewModel.isNpcLoading ? '응답 중...' : '말하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
