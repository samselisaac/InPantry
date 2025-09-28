import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DatabaseService {
  final _db = FirebaseDatabase.instance.ref();

  // returns current user db reference
  // if no login, creates guest session
  Future<DatabaseReference> getSessionRef() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return _db.child('sessions').child(user.uid);
    } else {
      final prefs = await SharedPreferences.getInstance();
      var guestId = prefs.getString('guestId');
      if (guestId == null) {
        guestId = 'guest_${Random().nextInt(1 << 32)}';
        prefs.setString('guestId', guestId);
      }
      return _db.child('guest_sessions').child(guestId);
    }
  }

  Future<void> startSession() async {
    final ref = await getSessionRef();
    await ref.update({
      'startedAt': ServerValue.timestamp,
      'lastActive': ServerValue.timestamp,
    });
  }

  Future<void> updateLastActive() async {
    final ref = await getSessionRef();
    await ref.child('lastActive').set(ServerValue.timestamp);
  }

  Stream<DatabaseEvent> watchSession() async* {
    final ref = await getSessionRef();
    yield* ref.onValue;
  }
}
