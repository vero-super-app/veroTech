// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id, fromAppId, toAppId, text;
  final DateTime ts;
  ChatMessage({
    required this.id,
    required this.fromAppId,
    required this.toAppId,
    required this.text,
    required this.ts,
  });
  bool isMine(String myAppId) => fromAppId == myAppId;

  factory ChatMessage.fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final ts = (m['ts'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ChatMessage(
      id: d.id,
      fromAppId: '${m['fromAppId'] ?? ''}',
      toAppId: '${m['toAppId'] ?? ''}',
      text: '${m['text'] ?? ''}',
      ts: ts,
    );
  }
}

class ChatThread {
  final String id;
  final List<String> participantsAppIds;
  final Map<String, dynamic> participants; // appId -> {name,avatar}
  final String lastText;
  final DateTime updatedAt;

  ChatThread({
    required this.id,
    required this.participantsAppIds,
    required this.participants,
    required this.lastText,
    required this.updatedAt,
  });

  String otherId(String me) => participantsAppIds.firstWhere((x) => x != me, orElse: () => me);

  factory ChatThread.fromSnap(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final ts = (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ChatThread(
      id: d.id,
      participantsAppIds: (m['participantsAppIds'] as List? ?? const []).map((e) => '$e').toList(),
      participants: (m['participants'] as Map<String, dynamic>? ?? const {}),
      lastText: '${m['lastText'] ?? ''}',
      updatedAt: ts,
    );
  }
}

class ChatService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // Ensure Firebase Core is ready. Your main.dart already does initializeApp(),
  // so this usually returns immediately.
  static Future<void> _ensureCore() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(); // no options needed; main.dart handled it
      } catch (_) {
        // Swallow: if another place already initialized in a race, this will throw.
      }
    }
  }

  static Future<String> myAppUserId() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString('userId') ?? sp.getInt('userId')?.toString();
    return (s == null || s.isEmpty) ? 'guest' : s;
  }

  static Future<User> ensureFirebaseAuth({String? firebaseCustomToken}) async {
    await _ensureCore();
    final existing = _auth.currentUser;
    if (existing != null) return existing;

    if (firebaseCustomToken != null && firebaseCustomToken.isNotEmpty) {
      final cred = await _auth.signInWithCustomToken(firebaseCustomToken);
      return cred.user!;
    }
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  static Future<void> lockUidMapping(String appUserId) async {
    final uid = _auth.currentUser!.uid; // call ensureFirebaseAuth() before this
    final ref = _db.collection('profiles').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, {
          'appUserId': appUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static String threadIdForApp(String a, String b) {
    final x = a.trim(), y = b.trim();
    return (x.compareTo(y) < 0) ? '${x}_$y' : '${y}_$x';
  }

  static Stream<List<ChatThread>> threadsStream(String myAppId) {
    return _db
        .collection('threads')
        .where('participantsAppIds', arrayContains: myAppId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => ChatThread.fromSnap(d)).toList());
  }

  static Stream<List<ChatMessage>> messagesStream(String threadId) {
    return _db
        .collection('threads').doc(threadId)
        .collection('messages')
        .orderBy('ts')
        .snapshots()
        .map((qs) => qs.docs.map((d) => ChatMessage.fromSnap(d)).toList());
  }

  static Future<void> ensureThread({
    required String myAppId,
    required String peerAppId,
    String? myName,
    String? myAvatar,
    String? peerName,
    String? peerAvatar,
  }) async {
    final id = threadIdForApp(myAppId, peerAppId);
    final ref = _db.collection('threads').doc(id);
    await ref.set({
      'participantsAppIds': [myAppId, peerAppId],
      'participants': {
        myAppId: {'name': myName, 'avatar': myAvatar},
        peerAppId: {'name': peerName, 'avatar': peerAvatar},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> sendMessage({
    required String myAppId,
    required String peerAppId,
    required String text,
  }) async {
    final id = threadIdForApp(myAppId, peerAppId);
    final tRef = _db.collection('threads').doc(id);
    final mRef = tRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    await _db.runTransaction((tx) async {
      tx.set(mRef, {
        'fromAppId': myAppId,
        'toAppId': peerAppId,
        'text': text,
        'ts': now,
      });
      tx.set(tRef, {
        'updatedAt': now,
        'lastText': text,
      }, SetOptions(merge: true));
    });
  }
}
