class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final DateTime sentAt;
}
