import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../application/rule_sets_provider.dart';
import '../../../shared/auth/auth_user_provider.dart';
import '../../../shared/profile/owner_name_provider.dart';
import '../domain/rule_set_rules.dart';
import '../domain/share_code.dart';

class RuleSetDetailScreen extends ConsumerWidget {
  const RuleSetDetailScreen({super.key, required this.ruleSetId});

  final String ruleSetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleSetAsync = ref.watch(ruleSetByIdProvider(ruleSetId));

    return ruleSetAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

        final followedIdsAsync = ref.watch(followedRuleSetIdsProvider);
        final isFollowed =
            followedIdsAsync.value?.contains(ruleSet.id) ?? false;
        final ownerUidAsync = ref.watch(ownerUidProvider);
        final ownerUid = ownerUidAsync.value;
        final ownerNameAsync = ref.watch(ownerNameProvider);
        final currentOwnerName =
            ownerNameAsync.asData?.value ?? ownerNameDefaultValue;
        final isOwner = ownerUid != null && ruleSet.ownerUid == ownerUid;
        final displayOwnerName = isOwner ? currentOwnerName : ruleSet.ownerName;

        return Scaffold(
          appBar: AppBar(
            title: Text(ruleSet.name),
            actions: [
              if (!isOwner)
                IconButton(
                  onPressed: () => _toggleFollow(
                    context,
                    ref,
                    ruleSetId: ruleSet.id,
                    isFollowed: isFollowed,
                    isPublic: ruleSet.isPublic,
                    ruleSetOwnerUid: ruleSet.ownerUid,
                  ),
                  icon: Icon(isFollowed ? Icons.star : Icons.star_border),
                  tooltip: isFollowed ? 'フォロー解除' : 'フォロー',
                ),
              if (isOwner)
                IconButton(
                  onPressed: () => context.goNamed(
                    'ruleset-edit',
                    pathParameters: {'id': ruleSet.id},
                  ),
                  icon: const Icon(Icons.edit),
                  tooltip: '編集',
                ),
              IconButton(
                onPressed: () => _confirmDelete(context, ref, ruleSet.id),
                icon: const Icon(Icons.delete_outline),
                tooltip: '削除',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _HeaderCard(
                name: ruleSet.name,
                description: ruleSet.description,
                ownerName: displayOwnerName,
                shareCode: ruleSet.shareCode,
                isPublic: ruleSet.isPublic,
                updatedAtLabel: ruleSet.updatedAtLabel,
              ),
              const SizedBox(height: 16),
              if (ruleSet.rules != null)
                _RuleSummarySection(rules: ruleSet.rules!),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _toggleFollow(
  BuildContext context,
  WidgetRef ref, {
  required String ruleSetId,
  required bool isFollowed,
  required bool isPublic,
  required String? ruleSetOwnerUid,
}) async {
  final ownerUid = await ref.read(ownerUidProvider.future);
  if (ruleSetOwnerUid != null && ownerUid == ruleSetOwnerUid) {
    return;
  }
  if (isFollowed && isPublic) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フォロー解除の確認'),
          content: const Text('フォローを解除すると、このルールセットは一覧で表示されなくなります。よろしいでしょうか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('解除する'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
  }
  final repository = ref.read(ruleSetRepositoryProvider);
  if (isFollowed) {
    await repository.unfollowRuleSet(ownerUid: ownerUid, ruleSetId: ruleSetId);
  } else {
    await repository.followRuleSet(ownerUid: ownerUid, ruleSetId: ruleSetId);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String ruleSetId,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('ルールセットを削除しますか？'),
        content: const Text('この操作は取り消せません。共有コードも破棄されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      );
    },
  );
  if (result != true) return;
  final repository = ref.read(ruleSetRepositoryProvider);
  await repository.deleteRuleSet(ruleSetId);
  if (!context.mounted) return;
  context.goNamed('ruleset-list');
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.description,
    required this.ownerName,
    required this.shareCode,
    required this.isPublic,
    required this.updatedAtLabel,
  });

  final String name;
  final String description;
  final String ownerName;
  final String? shareCode;
  final bool isPublic;
  final String updatedAtLabel;

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
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      const Icon(Icons.share, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Text(
                          '共有コード $shareCode',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () =>
                            _openShareSheet(context, shareCode!, shareUrl!),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('共有'),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.update, size: 18),
                  const SizedBox(width: 6),
                  Text(updatedAtLabel),
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

  void _openShareSheet(
    BuildContext context,
    String shareCode,
    String shareUrl,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.9;
        return SizedBox(
          height: maxHeight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: Column(
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
                const SizedBox(height: 8),
                Text(
                  '共有コードは一度公開すると変更されません。非公開に戻しても同じコードが使われます。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: shareUrl,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copyText(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('コピーしました')));
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
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
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

class _RuleSummarySection extends StatelessWidget {
  const _RuleSummarySection({required this.rules});

  final RuleSetRules rules;

  @override
  Widget build(BuildContext context) {
    final lines = <_RuleLine>[
      _RuleLine('対局人数', rules.players == PlayerCount.four ? '4人' : '3人'),
      _RuleLine('対局形式', switch (rules.matchType) {
        MatchType.tonpuu => '東風',
        MatchType.tonnan => '東南',
        MatchType.isshou => '一荘',
      }),
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
      _RuleLine('先付け', switch (rules.sakizuke) {
        SakizukeRule.complete => '完全先付け',
        SakizukeRule.ato => '後付け',
        SakizukeRule.naka => '中付け',
      }),
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
      _RuleLine(
        '流し満貫',
        rules.nagashiMangan == NagashiManganRule.on ? 'あり' : 'なし',
      ),
      _RuleLine(
        '七対子４枚使い',
        rules.chiitoitsuFourTiles == ChiitoitsuFourTilesRule.on ? 'あり' : 'なし',
      ),
      _RuleLine('西入', rules.shaNyu == ShaNyuRule.on ? 'あり' : 'なし'),
      if (rules.shaNyu == ShaNyuRule.on)
        _RuleLine(
          '西入時の進行',
          rules.shaNyuOption == ShaNyuOption.suddenDeath ? 'サドンデス' : '西場終了まで続行',
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
            : rules.specialDora
                  .map((d) {
                    switch (d) {
                      case SpecialDora.gold:
                        return '金ドラ';
                      case SpecialDora.hana:
                        return '花牌';
                      case SpecialDora.nuki:
                        return '抜きドラ';
                    }
                  })
                  .join(' / '),
      ),
      if (rules.players == PlayerCount.three)
        _RuleLine('北抜き', (rules.threePlayer?.northNuki ?? false) ? 'あり' : 'なし'),
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
        const SizedBox(height: 16),
        _FreeTextSection(text: rules.freeText),
      ],
    );
  }
}

class _FreeTextSection extends StatelessWidget {
  const _FreeTextSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('自由入力', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              text.trim().isEmpty ? '未入力' : text.trim(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
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
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                MediaQuery.of(context).orientation == Orientation.landscape;
            final width = constraints.maxWidth;
            final crossAxisCount = isLandscape
                ? (width >= 740 ? 4 : 3)
                : (width >= 900 ? 3 : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
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
                        Text(
                          line.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
