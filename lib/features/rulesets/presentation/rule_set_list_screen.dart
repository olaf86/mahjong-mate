import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/branding/app_logo.dart';
import '../application/rule_sets_provider.dart';
import '../domain/rule_category.dart';
import '../domain/rule_set.dart';
import '../domain/rule_set_rules.dart';
import '../domain/share_code.dart';

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
        child: ruleSets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(error: error),
          data: (items) => Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: Colors.white.withOpacity(0.001),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        const AppLogo(size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '雀メイト',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => context.pushNamed('settings-owner'),
                        icon: const Icon(Icons.settings),
                        tooltip: 'オーナー名',
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Text(
                            '麻雀ルールを仲間と共有しよう',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => _openShareCodeDialog(context),
                            icon: const Icon(Icons.key),
                            label: const Text('共有コードで開く'),
                          ),
                          const SizedBox(height: 24),
                          if (items.isEmpty)
                            const _EmptyState()
                          else
                            ...items.map((ruleSet) => _RuleSetCard(ruleSet: ruleSet)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openShareCodeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('共有コードで開く'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '例: MJM-AB12',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final code = controller.text.trim();
                Navigator.of(context).pop(code);
              },
              child: const Text('開く'),
            ),
          ],
        );
      },
    );
    if (result == null || result.trim().isEmpty) {
      return;
    }
    final normalized = normalizeShareCode(result);
    if (normalized.isEmpty) {
      return;
    }
    if (!context.mounted) return;
    context.go('/r/$normalized');
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
    final rules = ruleSet.rules;
    final tiles = rules == null ? null : _buildRuleTiles(rules);

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
                if (tiles == null)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RuleCategory.values.map((category) {
                      final count = categoryCounts[category] ?? 0;
                      return _MiniTag(label: '${category.label} $count');
                    }).toList(),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: tiles.map((tile) => _RuleTile(tile: tile)).toList(),
                  ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'オーナー: ${ruleSet.ownerName}',
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    if (ruleSet.shareCode != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '共有コード ${ruleSet.shareCode}',
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RuleTileData> _buildRuleTiles(RuleSetRules rules) {
    final tiles = <_RuleTileData>[];
    final isThreePlayer = rules.players == PlayerCount.three;
    final standardStarting = isThreePlayer ? 35000 : 25000;
    final standardReturn = isThreePlayer ? 40000 : 30000;
    final standardOka = (standardReturn - standardStarting) * (isThreePlayer ? 3 : 4);

    tiles.addAll([
      _RuleTileData(
        label: '人数',
        value: rules.players == PlayerCount.four ? '4人' : '3人',
        isStandard: rules.players == PlayerCount.four,
      ),
      _RuleTileData(
        label: '形式',
        value: _matchTypeLabel(rules.matchType),
        isStandard: rules.matchType == MatchType.tonnan,
      ),
      _RuleTileData(
        label: '持点',
        value: '${rules.startingPoints}',
        isStandard: rules.startingPoints == standardStarting,
      ),
      _RuleTileData(
        label: '返点',
        value: '${rules.score.returnPoints}',
        isStandard: rules.score.returnPoints == standardReturn,
      ),
      _RuleTileData(
        label: 'オカ',
        value: '${_calcOka(rules)}',
        isStandard: _calcOka(rules) == standardOka,
      ),
      _RuleTileData(
        label: '食ﾀﾝ',
        value: rules.kuitan == KuitanRule.on ? 'あり' : 'なし',
        isStandard: rules.kuitan == KuitanRule.on,
      ),
      _RuleTileData(
        label: '先付',
        value: _sakizukeLabel(rules.sakizuke),
        isStandard: rules.sakizuke == SakizukeRule.ato,
      ),
      _RuleTileData(
        label: '頭ﾊﾈ',
        value: rules.headBump == HeadBumpRule.atama ? '頭ハネ' : 'ダブロン',
        isStandard: rules.headBump == HeadBumpRule.atama,
      ),
      _RuleTileData(
        label: '箱ﾃﾝ',
        value: rules.boxTenThreshold == BoxTenThreshold.zero ? '0点以下' : 'マイナス',
        isStandard: rules.boxTenThreshold == BoxTenThreshold.zero,
      ),
      _RuleTileData(
        label: '箱後',
        value: rules.boxTenBehavior == BoxTenBehavior.end ? '終了' : '続行',
        isStandard: rules.boxTenBehavior == BoxTenBehavior.end,
      ),
      _RuleTileData(
        label: 'ﾄﾞﾗ',
        value: _doraLabel(rules),
        isStandard: rules.kandora == DoraRule.on &&
            rules.uradora == DoraRule.on &&
            rules.redDora.enabled &&
            rules.redDora.count == 3,
      ),
      _RuleTileData(
        label: '特ﾄﾞﾗ',
        value: _specialDoraLabel(rules.specialDora),
        isStandard: rules.specialDora.isEmpty,
      ),
      if (isThreePlayer)
        _RuleTileData(
          label: '北抜',
          value: rules.threePlayer?.northNuki == true ? 'あり' : 'なし',
          isStandard: rules.threePlayer?.northNuki == true,
        ),
      _RuleTileData(
        label: 'ｳﾏ',
        value: rules.score.uma,
        isStandard: _normalizeUma(rules.score.uma) == '20-10',
      ),
      _RuleTileData(
        label: '立棒',
        value: rules.score.riichiStick == RiichiStickRule.topTake ? 'トップ' : '均等',
        isStandard: rules.score.riichiStick == RiichiStickRule.topTake,
      ),
      _RuleTileData(
        label: '5本場2翻',
        value: rules.goRenchanTwoHan == GoRenchanTwoHanRule.on ? 'あり' : 'なし',
        isStandard: rules.goRenchanTwoHan == GoRenchanTwoHanRule.off,
      ),
      _RuleTileData(
        label: 'ｵｰﾗｽ止',
        value: rules.oorasuStop == OorasuStopRule.on ? 'あり' : 'なし',
        isStandard: rules.oorasuStop == OorasuStopRule.on,
      ),
    ]);

    return tiles;
  }

  String _matchTypeLabel(MatchType type) {
    switch (type) {
      case MatchType.tonpuu:
        return '東風';
      case MatchType.tonnan:
        return '東南';
      case MatchType.isshou:
        return '一荘';
    }
  }

  String _sakizukeLabel(SakizukeRule rule) {
    switch (rule) {
      case SakizukeRule.complete:
        return '完全';
      case SakizukeRule.ato:
        return '後付け';
      case SakizukeRule.naka:
        return '中付け';
    }
  }

  String _doraLabel(RuleSetRules rules) {
    final kandora = rules.kandora == DoraRule.on ? '槓○' : '槓×';
    final uradora = rules.uradora == DoraRule.on ? '裏○' : '裏×';
    final red = rules.redDora.enabled ? '赤${rules.redDora.count}' : '赤×';
    return '$kandora$uradora$red';
  }

  String _specialDoraLabel(List<SpecialDora> items) {
    if (items.isEmpty) return 'なし';
    final labels = items.map((item) {
      switch (item) {
        case SpecialDora.gold:
          return '金';
        case SpecialDora.hana:
          return '花';
        case SpecialDora.nuki:
          return '抜き';
      }
    }).toList();
    return labels.join('・');
  }

  int _calcOka(RuleSetRules rules) {
    final players = rules.players == PlayerCount.three ? 3 : 4;
    return (rules.score.returnPoints - rules.startingPoints) * players;
  }

  String _normalizeUma(String value) {
    return value.replaceAll(' ', '').trim();
  }

}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2D6C8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF3A2F25),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _RuleTileData {
  const _RuleTileData({
    required this.label,
    required this.value,
    required this.isStandard,
  });

  final String label;
  final String value;
  final bool isStandard;
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.tile});

  final _RuleTileData tile;

  @override
  Widget build(BuildContext context) {
    final background = tile.isStandard ? const Color(0xFFE6F0E8) : const Color(0xFFF6EAE1);
    final border = tile.isStandard ? const Color(0xFFD1E0D5) : const Color(0xFFE6CDBB);
    final textColor = tile.isStandard ? const Color(0xFF2D3F33) : const Color(0xFF4F3A2A);

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tile.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            tile.value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('まだルールセットがありません。', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '右下の「新規作成」から最初のルールセットを追加してください。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('読み込みに失敗しました。', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
