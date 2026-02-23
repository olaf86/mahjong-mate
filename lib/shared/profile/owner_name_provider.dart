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
    return prefs.getString(_ownerNameKey) ?? ownerNameDefaultValue;
  }

  Future<void> setOwnerName(String name) async {
    final trimmed = name.trim();
    final value = trimmed.isEmpty ? ownerNameDefaultValue : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerNameKey, value);
    try {
      final ownerUid = await ref.read(ownerUidProvider.future);
      await _syncOwnerNameToRuleSets(ownerUid: ownerUid, ownerName: value);
    } catch (_) {
      // Keep local save even if remote sync fails.
    }
    state = AsyncData(value);
  }

  Future<void> _syncOwnerNameToRuleSets({
    required String ownerUid,
    required String ownerName,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('rule_sets')
        .where('ownerUid', isEqualTo: ownerUid)
        .get();

    const batchLimit = 500;
    WriteBatch? batch;
    var count = 0;

    for (final doc in snapshot.docs) {
      batch ??= firestore.batch();
      batch.update(doc.reference, {
        'ownerName': ownerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      count++;

      if (count == batchLimit) {
        await batch.commit();
        batch = null;
        count = 0;
      }
    }

    if (batch != null && count > 0) {
      await batch.commit();
    }
  }
}
