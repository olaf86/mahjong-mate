import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';
import '../domain/rule_item.dart';

class RuleSetDetailScreen extends ConsumerWidget {
  const RuleSetDetailScreen({super.key, required this.ruleSetId});

  final String ruleSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleSet = ref.watch(ruleSetByIdProvider(ruleSetId));
    if (ruleSet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ルールセットが見つかりません')),
        body: const Center(child: Text('指定されたルールセットは存在しません。')),
      );
    }

    final grouped = <RuleCategory, List<RuleItem>>{};
    for (final item in ruleSet.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ruleSet.name),
        actions: [
          IconButton(
            onPressed: () => context.goNamed(
              'ruleset-edit',
              pathParameters: {'id': ruleSet.id},
            ),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _HeaderCard(
            name: ruleSet.name,
            description: ruleSet.description,
            ownerName: ruleSet.ownerName,
            shareCode: ruleSet.shareCode,
            isPublic: ruleSet.isPublic,
          ),
          const SizedBox(height: 16),
          ...RuleCategory.values.map((category) {
            final items = grouped[category] ?? const [];
            return _CategorySection(category: category, items: items);
          }),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.description,
    required this.ownerName,
    required this.shareCode,
    required this.isPublic,
  });

  final String name;
  final String description;
  final String ownerName;
  final String? shareCode;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5EBDD), Color(0xFFE7F3F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFE2D6C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, size: 18),
                  const SizedBox(width: 6),
                  Text(ownerName),
                ],
              ),
              if (shareCode != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.share, size: 18),
                    const SizedBox(width: 6),
                    Text('共有コード $shareCode'),
                  ],
                ),
              if (isPublic)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 6),
                    Text('公開配信中'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.items});

  final RuleCategory category;
  final List<RuleItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(
              'まだルールが登録されていません。',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(item.description),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
