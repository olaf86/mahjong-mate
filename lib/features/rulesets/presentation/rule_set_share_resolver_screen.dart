import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/auth/auth_user_provider.dart';
import '../../../shared/profile/auto_follow_provider.dart';
import '../application/rule_sets_provider.dart';
import '../data/rule_set_repository.dart';
import '../domain/share_code.dart';

class RuleSetShareResolverScreen extends ConsumerStatefulWidget {
  const RuleSetShareResolverScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  ConsumerState<RuleSetShareResolverScreen> createState() =>
      _RuleSetShareResolverScreenState();
}

class _RuleSetShareResolverScreenState
    extends ConsumerState<RuleSetShareResolverScreen> {
  bool _navigated = false;
  String? _followedRuleSetId;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeShareCode(widget.shareCode);
    final ruleSetAsync = ref.watch(ruleSetByShareCodeProvider(normalized));
    final autoFollowAsync = ref.watch(autoFollowProvider);

    return ruleSetAsync.when(
      loading: () => _LoadingScreen(label: '共有ルールセットを読み込み中...'),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: Center(child: Text(error.toString())),
      ),
      data: (ruleSet) {
        if (ruleSet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('共有コードが見つかりません')),
            body: const Center(child: Text('指定された共有コードは存在しません。')),
          );
        }
        if (!_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _maybeAutoFollow(ruleSet.id, autoFollowAsync.value);
            if (!mounted) return;
            context.goNamed(
              'ruleset-detail',
              pathParameters: {'id': ruleSet.id},
            );
          });
        }
        return _LoadingScreen(label: 'ルールセットを開いています...');
      },
    );
  }

  Future<void> _maybeAutoFollow(String ruleSetId, bool? autoFollow) async {
    if (autoFollow != true) return;
    if (_followedRuleSetId == ruleSetId) return;
    _followedRuleSetId = ruleSetId;
    final ownerUid = await ref.read(ownerUidProvider.future);
    final repository = ref.read(ruleSetRepositoryProvider);
    await repository.followRuleSet(ownerUid: ownerUid, ruleSetId: ruleSetId);
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}
