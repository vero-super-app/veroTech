// lib/Pages/Home/Messages.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:vero360_app/services/chat_service.dart';

class MessagePage extends StatefulWidget {
  final String peerAppId;                // REQUIRED: app user id of the seller
  final String? peerName;                // optional UI
  final String? peerAvatarUrl;           // optional UI
  const MessagePage({
    Key? key,
    required this.peerAppId,
    this.peerName,
    this.peerAvatarUrl, required String peerId,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  String? _me;
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Make sure Firebase auth exists (anon or custom token)
    await ChatService.ensureFirebaseAuth();
    final me = await ChatService.myAppUserId();
    setState(() => _me = me);

    // Ensure thread metadata (names/avatars) exists
    await ChatService.ensureThread(
      myAppId: me,
      peerAppId: widget.peerAppId,
      peerName: widget.peerName,
      peerAvatar: widget.peerAvatarUrl,
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _threadId => ChatService.threadIdForApp(_me!, widget.peerAppId);

  Future<void> _send() async {
    final txt = _input.text.trim();
    if (txt.isEmpty || _me == null) return;
    _input.clear();
    await ChatService.sendMessage(
      myAppId: _me!,
      peerAppId: widget.peerAppId,
      text: txt,
    );
    // jump to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.peerName ?? 'Chat';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if ((widget.peerAvatarUrl ?? '').isNotEmpty)
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(widget.peerAvatarUrl!))
            else
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: _me == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: ChatService.messagesStream(_threadId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(child: Text('Messages unavailable\n${snap.error}'));
                      }
                      final msgs = snap.data ?? const <ChatMessage>[];
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final mine = m.isMine(_me!);
                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * (kIsWeb ? 0.55 : 0.7),
                              ),
                              decoration: BoxDecoration(
                                color: mine ? Colors.green.shade600 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(color: mine ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Type a message…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
