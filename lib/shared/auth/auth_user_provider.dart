import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.userChanges();
});

final currentUserUidProvider = Provider<String?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  ref.watch(authStateProvider);
  return auth.currentUser?.uid;
});

final ownerUidProvider = FutureProvider<String>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  ref.watch(authStateProvider);
  final currentUser = auth.currentUser;
  if (currentUser != null) {
    return currentUser.uid;
  }
  final credential = await auth.signInAnonymously();
  return credential.user!.uid;
});
