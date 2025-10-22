// lib/Pages/Home/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:vero360_app/services/chat_service.dart';
import 'package:vero360_app/Pages/Home/Messages.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String? _myAppId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await ChatService.ensureFirebaseAuth();          // anon or custom token
      final appId = await ChatService.myAppUserId();
      try { await ChatService.lockUidMapping(appId); } catch (_) {}
      if (!mounted) return;
      setState(() => _myAppId = appId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Chat init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }
    final me = _myAppId;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ChatThread>>(                // ← typed
        stream: ChatService.threadsStream(me),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Chats unavailable:\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text('No chats yet.'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final t = items[i];
              final otherId = t.otherId(me);
              final meta = (t.participants[otherId] as Map?) ?? const {};
              final name = '${meta['name'] ?? 'Contact'}';
              final avatar = '${meta['avatar'] ?? ''}';
              return ListTile(
                leading: avatar.isNotEmpty
                    ? CircleAvatar(backgroundImage: NetworkImage(avatar))
                    : const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(t.lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(_fmtTime(t.updatedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessagePage(
                      peerAppId: otherId,
                      peerName: name,
                      peerAvatarUrl: avatar, peerId: '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ap';
    }
    return '${dt.month}/${dt.day}/${dt.year % 100}';
  }
}
