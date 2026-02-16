import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final ownerUidProvider = FutureProvider<String>((ref) async {
  final auth = ref.watch(firebaseAuthProvider);
  final user = await ref.watch(authStateProvider.future);
  if (user != null) {
    return user.uid;
  }
  final credential = await auth.signInAnonymously();
  return credential.user!.uid;
});
