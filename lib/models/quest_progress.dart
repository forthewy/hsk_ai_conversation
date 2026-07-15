import 'package:flutter/material.dart';


class QuestProgress {
  final String questId;
  final int currentCount;
  final Set<String> completedNpcIds;

  const QuestProgress({
    required this.questId,
    required this.currentCount,
    required this.completedNpcIds,

  });

  QuestProgress copyWith({
    int? currentCount,
    Set<String>? completedNpcIds,
  }) {
    debugPrint("currentCount : ${currentCount}");
    return QuestProgress(
      questId: questId,
      currentCount: currentCount ?? this.currentCount,
      completedNpcIds: completedNpcIds ?? this.completedNpcIds,
    );
  }
}