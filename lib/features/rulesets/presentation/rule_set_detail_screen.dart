import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';
import '../domain/rule_item.dart';
import '../domain/rule_set_rules.dart';
import '../domain/share_code.dart';

class RuleSetDetailScreen extends ConsumerWidget {
  const RuleSetDetailScreen({super.key, required this.ruleSetId});

  final String ruleSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleSetAsync = ref.watch(ruleSetByIdProvider(ruleSetId));

    return ruleSetAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('読み込みに失敗しました')),
        body: Center(child: Text(error.toString())),
      ),
      data: (ruleSet) {
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
              if (ruleSet.rules != null)
                _RuleSummarySection(rules: ruleSet.rules!)
              else
                ...RuleCategory.values.map((category) {
                  final items = grouped[category] ?? const [];
                  return _CategorySection(category: category, items: items);
                }),
            ],
          ),
        );
      },
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
    final shareUrl = shareCode == null ? null : shareUrlFor(shareCode!);
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
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _openShareSheet(context, shareCode!, shareUrl!),
                      child: const Text('共有'),
                    ),
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

  void _openShareSheet(BuildContext context, String shareCode, String shareUrl) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('共有', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ShareRow(
                label: '共有コード',
                value: shareCode,
                onCopy: () => _copyText(context, shareCode),
              ),
              const SizedBox(height: 8),
              _ShareRow(
                label: '共有URL',
                value: shareUrl,
                onCopy: () => _copyText(context, shareUrl),
                onShare: () => Share.share(shareUrl),
              ),
              const SizedBox(height: 16),
              Center(
                child: QrImageView(
                  data: shareUrl,
                  size: 160,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyText(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コピーしました')),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.onShare,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'コピー',
            ),
            if (onShare != null)
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share, size: 18),
                tooltip: '共有',
              ),
          ],
        ),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 600
                        ? 3
                        : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 140,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                item.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RuleSummarySection extends StatelessWidget {
  const _RuleSummarySection({required this.rules});

  final RuleSetRules rules;

  @override
  Widget build(BuildContext context) {
    final lines = <_RuleLine>[
      _RuleLine('対局人数', rules.players == PlayerCount.four ? '4人' : '3人'),
      _RuleLine(
        '対局形式',
        switch (rules.matchType) {
          MatchType.tonpuu => '東風',
          MatchType.tonnan => '東南',
          MatchType.isshou => '一荘',
        },
      ),
      _RuleLine('持ち点', '${rules.startingPoints}点'),
      _RuleLine('返し点', '${rules.score.returnPoints}点'),
      _RuleLine('オカ', '${rules.score.oka}点'),
      _RuleLine(
        '箱テン判定',
        rules.boxTenThreshold == BoxTenThreshold.zero ? '0点以下の時点' : 'マイナス時点',
      ),
      _RuleLine(
        '箱テン後の扱い',
        rules.boxTenBehavior == BoxTenBehavior.end ? '終了' : '続行',
      ),
      _RuleLine('食いタン', rules.kuitan == KuitanRule.on ? 'あり' : 'なし'),
      _RuleLine(
        '先付け',
        switch (rules.sakizuke) {
          SakizukeRule.complete => '完全先付け',
          SakizukeRule.ato => '後付け',
          SakizukeRule.naka => '中付け',
        },
      ),
      _RuleLine(
        '頭ハネ/ダブロン',
        rules.headBump == HeadBumpRule.atama ? '頭ハネ' : 'ダブロン',
      ),
      _RuleLine(
        '連荘条件',
        rules.renchan == RenchanRule.oyaTenpai ? '親テンパイ' : '親流局',
      ),
      _RuleLine('オーラス止め', rules.oorasuStop == OorasuStopRule.on ? 'あり' : 'なし'),
      _RuleLine(
        '5本場以上2翻縛り',
        rules.goRenchanTwoHan == GoRenchanTwoHanRule.on ? 'あり' : 'なし',
      ),
    ];

    final doraLines = <_RuleLine>[
      _RuleLine('カンドラ', rules.kandora == DoraRule.on ? 'あり' : 'なし'),
      _RuleLine('裏ドラ', rules.uradora == DoraRule.on ? 'あり' : 'なし'),
      _RuleLine(
        '赤ドラ',
        rules.redDora.enabled ? 'あり (${rules.redDora.count}枚)' : 'なし',
      ),
      _RuleLine(
        '特殊ドラ',
        rules.specialDora.isEmpty
            ? 'なし'
            : rules.specialDora.map((d) {
                switch (d) {
                  case SpecialDora.gold:
                    return '金ドラ';
                  case SpecialDora.hana:
                    return '花牌';
                  case SpecialDora.nuki:
                    return '抜きドラ';
                }
              }).join(' / '),
      ),
      if (rules.players == PlayerCount.three)
        _RuleLine(
          '北抜き',
          (rules.threePlayer?.northNuki ?? false) ? 'あり' : 'なし',
        ),
    ];

    final scoreLines = <_RuleLine>[
      _RuleLine('ウマ', rules.score.uma),
      _RuleLine(
        'リーチ棒',
        rules.score.riichiStick == RiichiStickRule.topTake ? 'トップ総取り' : '分配',
      ),
    ];

    final advancedLines = <_RuleLine>[
      _RuleLine('複合役満', rules.yakuman.allowMultiple ? 'あり' : 'なし'),
      _RuleLine('ダブル役満', rules.yakuman.allowDouble ? 'あり' : 'なし'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleSummaryGroup(title: '基本ルール', lines: lines),
        const SizedBox(height: 16),
        _RuleSummaryGroup(title: 'ドラ設定', lines: doraLines),
        const SizedBox(height: 16),
        _RuleSummaryGroup(title: '得点配分（精算）', lines: scoreLines),
        const SizedBox(height: 16),
        _RuleSummaryGroup(title: '役満・特殊扱い', lines: advancedLines),
      ],
    );
  }
}

class _RuleSummaryGroup extends StatelessWidget {
  const _RuleSummaryGroup({required this.title, required this.lines});

  final String title;
  final List<_RuleLine> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 86,
          ),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final line = lines[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      line.value,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RuleLine {
  const _RuleLine(this.label, this.value);

  final String label;
  final String value;
}
