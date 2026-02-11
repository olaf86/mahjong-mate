import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/device/device_id_provider.dart';
import '../data/rule_set_repository.dart';
import '../domain/rule_set.dart';
import '../domain/share_code.dart';

final ruleSetRepositoryProvider = Provider<RuleSetRepository>((ref) {
  return RuleSetRepository(FirebaseFirestore.instance);
});

final ruleSetsProvider = StreamProvider<List<RuleSet>>((ref) async* {
  final deviceId = await ref.watch(deviceIdProvider.future);
  final repository = ref.watch(ruleSetRepositoryProvider);
  yield* repository.watchRuleSets(deviceId: deviceId);
});

final ruleSetByIdProvider = Provider.family<AsyncValue<RuleSet?>, String>((ref, id) {
  final ruleSets = ref.watch(ruleSetsProvider);
  return ruleSets.whenData((items) {
    for (final ruleSet in items) {
      if (ruleSet.id == id) {
        return ruleSet;
      }
    }
    return null;
  });
});

final ruleSetByShareCodeProvider = FutureProvider.family<RuleSet?, String>((ref, code) async {
  final normalized = normalizeShareCode(code);
  if (normalized.isEmpty) {
    return null;
  }
  final repository = ref.watch(ruleSetRepositoryProvider);
  return repository.fetchRuleSetByShareCode(normalized);
});
