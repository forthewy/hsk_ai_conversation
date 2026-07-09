import 'package:flutter/material.dart';

import '../models/npc_data.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/game_repository.dart';
import 'ai_service.dart';
import 'memory_extractor_service.dart';
import '../models/npc_state.dart';

class ConversationService {
  final AiService aiService;
  final GameRepository gameRepository;
  final ConversationRepository conversationRepository;
  final MemoryExtractorService memoryExtractor;

  ConversationService({
    required this.aiService,
    required this.gameRepository,
    required this.conversationRepository,
    required this.memoryExtractor,
  });

  // ai 장기기억 거름망
  static const _allowedTypes = ['name', 'goal', 'preference', 'relationship'];

  // 기억 추출 X 조건
  bool _shouldSkipMemoryExtraction(String text) {
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

  String _preprocessPlayerMessage(String text) {
    final normalized = text.trim().toLowerCase().replaceAll(
      RegExp(r'[!?.~\s]'),
      '',
    );

    const greetings = {
      '안녕',
      '안녕하세요',
      '반가워',
      '반갑습니다',
      'hi',
      'hello',
      'hey',
      '你好',
      '您好',
    };

    if (greetings.contains(normalized)) {
      return '(인사만 함)';
    }

    return text;
  }

  List<String> sampleKnownWords(List<String> words) {
    final copied = List<String>.from(words);
    copied.shuffle();
    return copied.take(5).toList();
  }

  Future<String> sendMessage({
    required NPCData npcData,
    required String playerMessage,
    required List<String> sampledWords,
    required int hskLevel,
    required NpcState state,
  }) async {
    await _extractAndSaveMemory(text: playerMessage, npcData: npcData);

    await conversationRepository.addRecentMessage(
      npcId: npcData.objectId,
      role: 'player',
      content: playerMessage,
    );

    // NPC에게 보낼 메시지만 전처리
    final npcMessage = _preprocessPlayerMessage(playerMessage);

    final reply = await aiService.npcChat(
      npc: npcData,
      playerMessage: npcMessage,
      playerMemory: gameRepository.getPlayerMemory(),
      recentMessages: conversationRepository.getRecentMessages(
        npcData.objectId,
      ),
      sampledWords: sampledWords,
      hskLevel: hskLevel,
      state: state,
    );
    debugPrint('5 npcChat 완료: $reply');

    debugPrint('현재 NPC 기억: ${npcData.memories}');

    await conversationRepository.addRecentMessage(
      npcId: npcData.objectId,
      role: 'npc',
      content: reply,
    );

    return reply;
  }

  Future<void> _extractAndSaveMemory({
    required String text,
    required NPCData npcData,
  }) async {
    if (_shouldSkipMemoryExtraction(text)) return;

    final extractedList = await memoryExtractor.extractMemory(
      playerMessage: text,
      allowedTypes: _allowedTypes,
    );

    for (final extracted in extractedList) {
      final type = extracted['type'];
      final value = extracted['value']?.trim();

      if (type == null || value == null || value.isEmpty) continue;

      if (type == 'name') {
        await gameRepository.savePlayerMemory(key: 'name', value: value);
      } else if (type == 'goal') {
        await gameRepository.savePlayerMemory(key: 'goal', value: value);
      } else if (type == 'preference') {
        await gameRepository.savePlayerMemory(key: 'preference', value: value);
      } else if (type == 'relationship') {
        npcData.memories.removeWhere((m) => m.startsWith('relationship:'));
        npcData.memories.add('relationship: $value');

        await gameRepository.saveNpcMemory(npcData);
      }
    }
  }
}
