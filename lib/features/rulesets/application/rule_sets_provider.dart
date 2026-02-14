import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/auth/auth_user_provider.dart';
import '../data/rule_set_repository.dart';
import '../domain/rule_set.dart';
import '../domain/share_code.dart';

final ruleSetRepositoryProvider = Provider<RuleSetRepository>((ref) {
  return RuleSetRepository(FirebaseFirestore.instance);
});

final ruleSetsProvider = StreamProvider<List<RuleSet>>((ref) async* {
  final ownerUid = await ref.watch(ownerUidProvider.future);
  final repository = ref.watch(ruleSetRepositoryProvider);
  yield* repository.watchRuleSets(ownerUid: ownerUid);
});

final followedRuleSetIdsProvider = StreamProvider<List<String>>((ref) async* {
  final ownerUid = await ref.watch(ownerUidProvider.future);
  final repository = ref.watch(ruleSetRepositoryProvider);
  yield* repository.watchFollowedRuleSetIds(ownerUid: ownerUid);
});

final followedRuleSetsProvider = StreamProvider<List<RuleSet>>((ref) async* {
  final ownerUid = await ref.watch(ownerUidProvider.future);
  final repository = ref.watch(ruleSetRepositoryProvider);
  yield* repository.watchFollowedRuleSets(ownerUid: ownerUid);
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
