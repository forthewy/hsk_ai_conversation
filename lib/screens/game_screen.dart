import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/NPCData.dart';
import '../models/game_object.dart';
import '../models/word_status.dart';
import '../services/ai_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

const maxRecentMessages = 20;

// 플레이어
class Player {
  double x;
  double y;

  Player({required this.x, required this.y});
}

// ai 장기기억 거름망
const allowedTypes = ['name', 'goal', 'preference', 'relationship'];

class _GameScreenState extends State<GameScreen> {
  bool shouldSkipMemoryExtraction(String text) {
    return text.endsWith('?') ||
        text.endsWith('？') ||
        text.contains('무엇') ||
        text.contains('어디') ||
        text.contains('왜') ||
        text.contains('어떻게') ||
        text.contains('언제') ||
        text.contains('누구') ||
        text.contains('몇');
  }

  Map<String, dynamic> getPlayerMemory() {
    return Map<String, dynamic>.from(playerMemoryBox.toMap());
  }

  late final Box npcMemoryBox;

  // 공동 기억 (전역 기억)
  late final Box playerMemoryBox;

  @override
  void initState() {
    super.initState();
    knownWords = getKnownWords();

    npcMemoryBox = Hive.box('npc_memory_box');
    playerMemoryBox = Hive.box('player_memory_box');
    loadNpcMemories();

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

  Future<void> saveExtractedMemory({
    required Map<String, String> extracted,
    required NPCData npcData,
  }) async {
    final type = extracted['type'];
    final value = extracted['value']?.trim();

    if (type == null || value == null || value.isEmpty) return;

    if (type == 'name') {
      await playerMemoryBox.put('name', value);
    } else if (type == 'goal') {
      await playerMemoryBox.put('goal', value);
    } else if (type == 'preference') {
      await playerMemoryBox.put('preference', value);
    } else if (type == 'relationship') {
      npcData.memories.removeWhere((m) => m.startsWith('relationship:'));

      npcData.memories.add('relationship: $value');

      await npcMemoryBox.put(
        npcData.objectId,
        List<String>.from(npcData.memories),
      );
    }

    debugPrint('기억 저장 완료: $extracted');
  }

  Future<void> addRecentMessage({
    required String npcId,
    required String role,
    required String content,
  }) async {
    final key = 'recent_$npcId';

    final oldMessages = npcMemoryBox.get(key, defaultValue: []);

    final messages = List<Map<String, String>>.from(
      oldMessages.map((e) => Map<String, String>.from(e)),
    );

    messages.add({'role': role, 'content': content});

    if (messages.length > maxRecentMessages) {
      messages.removeRange(0, messages.length - maxRecentMessages);
    }

    await npcMemoryBox.put(key, messages);
  }

  List<Map<String, String>> getRecentMessages(String npcId) {
    final raw = npcMemoryBox.get('recent_$npcId', defaultValue: []);

    return List<Map<String, String>>.from(
      raw.map((e) => Map<String, String>.from(e)),
    );
  }

  Future<void> loadNpcMemories() async {
    for (final npc in npcDatabase.values) {
      final memories = npcMemoryBox.get(npc.objectId);
      debugPrint('${npc.objectId} 불러온 기억: $memories');

      if (memories != null) {
        npc.memories.clear();
        npc.memories.addAll(List<String>.from(memories));
      }
      debugPrint('${npc.objectId} 현재 기억: ${npc.memories}');
    }
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
      greeting: "你好！",
    ),
    'student': NPCData(
      objectId: 'student',
      place: PlaceType.school,
      systemPrompt: '''
      당신은 학교에 다니는 학생입니다.
      친근하고 짧게 말합니다.
      질문하는 것을 좋아합니다.
      ''',
      memories: [],
      name: "학생",
      greeting: "你好！很高兴认识你",
      //greeting: "嗨！",
    ),
  };

  List<GameObject> objects = [];
  GameObject? interactableObject;
  final aiService = AiService();
  bool isNpcLoading = false;
  final player = Player(x: 100, y: 100);
  final double worldWidth = 400;
  final double worldHeight = 700;
  final double playerSize = 40;
  final dialogController = TextEditingController();
  GameObject? currentNpc;
  bool isInteracting = false;
  List<String> knownWords = [];
  List<String> sampledWords = [];
  int playerHskLevel = 1;
  final wordStatusBox = Hive.box('word_status_box');
  List<Map<String, String>> sessionMessages = [];

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
      isInteracting = true;
      currentNpc = npc;
      isTalking = true;

      sessionMessages.clear();

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
                        startDialog(
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
                      child: Text(npc.name),
                    );
                  })
                  .toList(),
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
              Positioned(
                top: 20,
                right: 20,
                child: PopupMenuButton<int>(
                  onSelected: (value) {
                    setState(() {
                      playerHskLevel = value;
                    });
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('HSK$playerHskLevel ▼'),
                  ),
                ),
              ),
              // 대화창
              if (isTalking) buildDialog(),
              // 기타 ui... 체력... ai 횟수 제한...buildUI(),
              if (interactableObject != null && !isInteracting)
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
    final npcData = npcDatabase[currentNpc!.npcDataId]!;
    final lastMessages = sessionMessages.length > 2
        ? sessionMessages.sublist(sessionMessages.length - 2)
        : sessionMessages;
    final npcDataId = currentNpc!.npcDataId;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Text(
                  currentNpc!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                IconButton(
                  onPressed: () {
                    setState(() {
                      isTalking = false;
                      isInteracting = false;
                      currentNpc = null;
                      playerText = '';
                      npcText = '';
                      dialogController.clear();
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const Divider(),
            // 대화
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastMessages.isEmpty)
                  Text('${currentNpc!.name}: ${npcData.greeting}')
                else
                  ...lastMessages.map((message) {
                    final speaker =
                    message['role'] == 'player'
                        ? '나'
                        : currentNpc!.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('$speaker: ${message['content']}'),
                    );
                  }),
              ],
            ),
            //Text(dialogText, style: const TextStyle(fontSize: 20)), // 대화 내용
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dialogController,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isNpcLoading
                      ? null
                      : () async {
                          final text = dialogController.text.trim();
                          if (text.isEmpty || currentNpc == null) return;

                          setState(() {
                            isNpcLoading = true;

                          });

                          try {
                            if (!shouldSkipMemoryExtraction(text)) {
                              debugPrint('1 입력 시작');
                              // final extracted = await aiService.extractMemory(
                              //   playerMessage: text,
                              //   allowedTypes: allowedTypes,
                              // );
                              final extractedList = await aiService
                                  .extractMemory(
                                    playerMessage: text,
                                    allowedTypes: allowedTypes,
                                  );

                              for (final extracted in extractedList) {
                                await saveExtractedMemory(
                                  extracted: extracted,
                                  npcData: npcData,
                                );
                              }

                              debugPrint('2 기억 추출 완료: $extractedList');
                            }

                            debugPrint('3 대화 저장 시작');

                            await addRecentMessage(
                              npcId: npcData.objectId,
                              role: 'player',
                              content: text,
                            );

                            debugPrint('4 npcChat 호출 시작');
                            knownWords.shuffle();
                            final sampledWords = knownWords.take(5).toList();
                            final reply = await aiService.npcChat(
                              npc: npcData,
                              playerMessage: text,
                              playerMemory: getPlayerMemory(),
                              recentMessages: getRecentMessages(
                                npcData.objectId,
                              ),
                              sampledWords: sampledWords,
                              hskLevel: playerHskLevel,
                            );

                            debugPrint('5 npcChat 완료: $reply');

                            debugPrint('현재 NPC 기억: ${npcData.memories}');

                            await addRecentMessage(
                              npcId: npcData.objectId,
                              role: 'npc',
                              content: reply,
                            );

                            setState(() {
                              sessionMessages.add({
                                'role': 'player',
                                'content': text,
                              });

                              sessionMessages.add({
                                'role': 'npc',
                                'content': reply,
                              });
                              dialogController.clear();
                            });
                          } finally {
                            setState(() {
                              isNpcLoading = false;
                            });
                          }
                        },
                  child: Text(isNpcLoading ? '응답 중...' : '입력'),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
