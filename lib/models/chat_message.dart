class ChatMessage {
  final String role; // user / ai
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map map) {
    return ChatMessage(
      role: map['role'],
      text: map['text'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}