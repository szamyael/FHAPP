import 'package:flutter/material.dart';

import '../../core/app_store.dart';
import '../../core/app_store_scope.dart';
import '../../models/account.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.title,
  });

  final String threadId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final Account? me = store.currentAccount;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = store.messagesForThread(widget.threadId)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = me != null && msg.senderId == me.id;
                final sender = store.accountById(msg.senderId);

                final bubbleBg = isMe
                  ? scheme.primary.withAlpha(isDark ? 56 : 26)
                  : scheme.surface;
                final bubbleBorder = Border.all(color: scheme.outline);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bubbleBg,
                        border: bubbleBorder,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender?.displayName ?? msg.senderId,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(msg.text),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                    ),
                    onSubmitted: (_) async {
                      if (me == null) return;
                      await _send(store, me);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: me == null
                      ? null
                      : () async {
                          await _send(store, me);
                        },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(AppStore store, Account me) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await store.sendMessage(
        threadId: widget.threadId,
        senderId: me.id,
        text: text,
      );
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }
}
