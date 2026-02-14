import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/auth/auth_user_provider.dart';
import '../application/rule_sets_provider.dart';
import '../data/rule_set_repository.dart';
import '../domain/rule_set.dart';

class FollowedRuleSetOrderScreen extends ConsumerStatefulWidget {
  const FollowedRuleSetOrderScreen({super.key});

  @override
  ConsumerState<FollowedRuleSetOrderScreen> createState() =>
      _FollowedRuleSetOrderScreenState();
}

class _FollowedRuleSetOrderScreenState
    extends ConsumerState<FollowedRuleSetOrderScreen> {
  List<RuleSet>? _localItems;

  @override
  Widget build(BuildContext context) {
    final ruleSets = ref.watch(followedRuleSetsProvider);
    final theme = Theme.of(context);
    const itemRadius = BorderRadius.all(Radius.circular(14));

    return Scaffold(
      appBar: AppBar(
        title: const Text('並び替え'),
      ),
      body: ruleSets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          final list = _currentItems(items);
          if (list.isEmpty) {
            return const Center(child: Text('フォロー中のルールセットがありません。'));
          }
          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            proxyDecorator: (child, _, __) {
              return Material(
                elevation: 6,
                color: Colors.transparent,
                shadowColor: Colors.black.withOpacity(0.2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: itemRadius,
                  ),
                  child: child,
                ),
              );
            },
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ruleSet = list[index];
              return Container(
                key: ValueKey(ruleSet.id),
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: theme.cardColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: itemRadius,
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.45),
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      ruleSet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) => _onReorder(list, oldIndex, newIndex),
          );
        },
      ),
    );
  }

  List<RuleSet> _currentItems(List<RuleSet> items) {
    if (_localItems == null || !_sameOrder(_localItems!, items)) {
      _localItems = List<RuleSet>.from(items);
    }
    return _localItems!;
  }

  bool _sameOrder(List<RuleSet> a, List<RuleSet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _onReorder(List<RuleSet> list, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    setState(() {
      _localItems = List<RuleSet>.from(list);
    });
    final ownerUid = await ref.read(ownerUidProvider.future);
    final repository = ref.read(ruleSetRepositoryProvider);
    await repository.updateFollowOrder(
      ownerUid: ownerUid,
      orderedRuleSetIds: list.map((item) => item.id).toList(),
    );
  }
}
