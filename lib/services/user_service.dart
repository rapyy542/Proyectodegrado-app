import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? 'Sin nombre',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'totalSavings': 0,
      });
    }
  }

  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updateSavings(String uid, num amount) async {
    await _db.collection('users').doc(uid).update({'totalSavings': amount});
  }
}
