// lib/Pages/Home/Messages.dart
import 'package:flutter/material.dart';

class MessagePage extends StatefulWidget {
  /// Seller's user id if available; otherwise a contact key (e.g., phone).
  final String peerId;

  /// Display name/avatar for the app bar.
  final String? peerName;
  final String? peerAvatarUrl;

  const MessagePage({
    Key? key,
    required this.peerId,
    this.peerName,
    this.peerAvatarUrl,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Text(
                widget.peerName ?? 'Chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('TODO: chat UI — connect socket & load messages'),
      ),
    );
  }
}
