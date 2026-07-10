import 'npc_state.dart';

class ConversationResult {
  final String reply;
  final NpcState state;

  ConversationResult({
    required this.reply,
    required this.state,
  });
}