import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  BlockService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<List<String>> getBlockedUsers(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return [];
    final list = (data['blockedUsers'] as List?) ?? [];
    return list.map((e) => e.toString()).toList();
  }

  Future<bool> isInteractionBlocked({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId == targetUserId) return false;
    final docs = await Future.wait([
      _firestore.collection('users').doc(currentUserId).get(),
      _firestore.collection('users').doc(targetUserId).get(),
    ]);
    final a = (docs[0].data()?['blockedUsers'] as List?) ?? [];
    final b = (docs[1].data()?['blockedUsers'] as List?) ?? [];
    final aBlocked = a.map((e) => e.toString()).toSet();
    final bBlocked = b.map((e) => e.toString()).toSet();
    return aBlocked.contains(targetUserId) || bBlocked.contains(currentUserId);
  }

  Future<void> blockUser(String targetUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) throw Exception('Not authenticated');
    await _firestore.collection('users').doc(me).set({
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String targetUserId) async {
    final me = _auth.currentUser?.uid;
    if (me == null) throw Exception('Not authenticated');
    await _firestore.collection('users').doc(me).set({
      'blockedUsers': FieldValue.arrayRemove([targetUserId]),
    }, SetOptions(merge: true));
  }
}


