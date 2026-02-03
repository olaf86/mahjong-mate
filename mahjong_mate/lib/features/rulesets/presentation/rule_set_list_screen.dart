import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';
import '../domain/rule_set.dart';

class RuleSetListScreen extends ConsumerWidget {
  const RuleSetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleSets = ref.watch(ruleSetsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed('ruleset-new'),
        icon: const Icon(Icons.add),
        label: const Text('新規作成'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text('Mahjong Mate', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'ルールセットを整理して、卓や雀荘へすぐ配信。',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'メインコミュニティの採用ルールと役の解釈を、いつでも最新版で共有できます。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ...ruleSets.map((ruleSet) => _RuleSetCard(ruleSet: ruleSet)),
          ],
        ),
      ),
    );
  }
}

class _RuleSetCard extends StatelessWidget {
  const _RuleSetCard({required this.ruleSet});

  final RuleSet ruleSet;

  @override
  Widget build(BuildContext context) {
    final categoryCounts = <RuleCategory, int>{};
    for (final item in ruleSet.items) {
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.goNamed(
            'ruleset-detail',
            pathParameters: {'id': ruleSet.id},
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ruleSet.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (ruleSet.isPublic)
                      const Icon(Icons.public, size: 18, color: Color(0xFF0F6B6B)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(ruleSet.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RuleCategory.values.map((category) {
                    final count = categoryCounts[category] ?? 0;
                    return Chip(label: Text('${category.label} $count'));
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified_user, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'オーナー: ${ruleSet.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    if (ruleSet.shareCode != null)
                      Flexible(
                        child: Text(
                          '共有コード ${ruleSet.shareCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
