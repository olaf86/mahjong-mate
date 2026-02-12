import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final ownerUidProvider = FutureProvider<String>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final current = auth.currentUser;
  if (current != null) {
    return current.uid;
  }
  final credential = await auth.signInAnonymously();
  return credential.user!.uid;
});
