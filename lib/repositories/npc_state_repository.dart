import 'package:hive/hive.dart';

import '../models/npc_state.dart';

class NpcStateRepository {
  final _box = Hive.box('npc_state_box');

  NpcState getState(String npcId) {
    final state = _box.get(
      npcId,
      defaultValue: NpcState.introduction.name,
    );

    return NpcState.values.byName(state);
  }

  Future<void> setState(
      String npcId,
      NpcState state,
      ) async {
    await _box.put(
      npcId,
      state.name,
    );
  }
}