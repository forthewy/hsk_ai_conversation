import 'package:flutter/material.dart';

import '../models/game_object.dart';
import '../models/npc_state.dart';

class GameViewModel extends ChangeNotifier {
  // -------변수-------
  bool isNpcLoading = false;
  GameObject? currentNpc;
  bool isInteracting = false;
  bool isTalking = false;
  List<Map<String, String>> sessionMessages = [];
  NpcState currentState = NpcState.introduction;
  int playerHskLevel = 1;

  // 대화 시작
  void startDialog(GameObject npc) {
    currentNpc = npc;
    isInteracting = true;
    isTalking = true;
    clearMessages();
  }

  // 메세지 보내기

  // 대화 종료
  void closeDialog() {
    currentNpc = null;
    isInteracting = false;
    isTalking = false;
    clearMessages();
  }

  // 메세지 추가
  void addMessage({required String role, required String content}) {
    sessionMessages.add({'role': role, 'content': content});

    notifyListeners();
  }

  // 세션 메세지 클리어
  void clearMessages() {
    sessionMessages.clear();
    notifyListeners();
  }

  // Npc 로딩
  void setNpcLoading(bool value) {
    isNpcLoading = value;
    notifyListeners();
  }

  // 마지막 메세지
  List<Map<String, String>> get lastMessages {
    return sessionMessages.length > 2
        ? sessionMessages.sublist(sessionMessages.length - 2)
        : sessionMessages;
  }

  // HSK 레벨 변경
  void setHskLevel(int value) {
    playerHskLevel = value;
    notifyListeners();
  }

  // -------getter-------
  bool get hasCurrentNpc => currentNpc != null;

  String get currentNpcName => currentNpc?.name ?? '';
}
