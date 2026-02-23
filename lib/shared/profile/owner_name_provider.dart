import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_user_provider.dart';

const String _ownerNameKey = 'owner_name';
const String ownerNameDefaultValue = 'あなた';

final ownerNameProvider = AsyncNotifierProvider<OwnerNameNotifier, String>(
  OwnerNameNotifier.new,
);

class OwnerNameNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(_ownerNameKey) ?? ownerNameDefaultValue;
    try {
      final ownerUid = await ref.read(ownerUidProvider.future);
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid);
      final snapshot = await docRef.get();
      final remote = _stringValue(snapshot.data()?['ownerName']);
      if (remote.isNotEmpty) {
        if (remote != local) {
          await prefs.setString(_ownerNameKey, remote);
        }
        return remote;
      }
      await docRef.set({
        'ownerName': local,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Use local fallback on Firestore/network errors.
    }
    return local;
  }

  Future<void> setOwnerName(String name) async {
    final trimmed = name.trim();
    final value = trimmed.isEmpty ? ownerNameDefaultValue : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerNameKey, value);
    try {
      final ownerUid = await ref.read(ownerUidProvider.future);
      await FirebaseFirestore.instance.collection('users').doc(ownerUid).set({
        'ownerName': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Keep local save even if remote sync fails.
    }
    state = AsyncData(value);
  }

  String _stringValue(Object? raw) {
    if (raw is String) {
      return raw.trim();
    }
    return '';
  }
}
