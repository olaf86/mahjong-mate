import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/rule_sets_provider.dart';
import '../domain/rule_set.dart';
import '../domain/rule_set_rules.dart';
import '../domain/rule_set_visibility.dart';
import '../../../shared/auth/auth_user_provider.dart';
import '../../../shared/profile/owner_name_provider.dart';

class RuleSetEditScreen extends ConsumerStatefulWidget {
  const RuleSetEditScreen({super.key, this.ruleSetId});

  final String? ruleSetId;

  @override
  ConsumerState<RuleSetEditScreen> createState() => _RuleSetEditScreenState();
}

class _RuleSetEditScreenState extends ConsumerState<RuleSetEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _startingPointsController;
  late final TextEditingController _returnPointsController;
  late final TextEditingController _redDoraCountController;
  late final TextEditingController _umaController;
  late final TextEditingController _freeTextController;
  bool _initialized = false;
  bool _saving = false;
  RuleSetVisibility _visibility = RuleSetVisibility.private;
  PlayerCount _players = PlayerCount.four;
  MatchType _matchType = MatchType.tonnan;
  BoxTenThreshold _boxTenThreshold = BoxTenThreshold.zero;
  BoxTenBehavior _boxTenBehavior = BoxTenBehavior.end;
  KuitanRule _kuitan = KuitanRule.on;
  SakizukeRule _sakizuke = SakizukeRule.ato;
  HeadBumpRule _headBump = HeadBumpRule.atama;
  RenchanRule _renchan = RenchanRule.oyaTenpai;
  OorasuStopRule _oorasuStop = OorasuStopRule.on;
  GoRenchanTwoHanRule _goRenchanTwoHan = GoRenchanTwoHanRule.off;
  NagashiManganRule _nagashiMangan = NagashiManganRule.on;
  ChiitoitsuFourTilesRule _chiitoitsuFourTiles = ChiitoitsuFourTilesRule.off;
  ShaNyuRule _shaNyu = ShaNyuRule.on;
  ShaNyuOption _shaNyuOption = ShaNyuOption.suddenDeath;
  DoraRule _kandora = DoraRule.on;
  DoraRule _uradora = DoraRule.on;
  bool _redDoraEnabled = true;
  final Set<SpecialDora> _specialDora = {};
  RiichiStickRule _riichiStick = RiichiStickRule.topTake;
  bool _yakumanMultiple = true;
  bool _yakumanDouble = true;
  bool _threeNorthNuki = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _startingPointsController = TextEditingController(text: '25000');
    _returnPointsController = TextEditingController(text: '30000');
    _redDoraCountController = TextEditingController(text: '3');
    _umaController = TextEditingController(text: '20-10');
    _freeTextController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startingPointsController.dispose();
    _returnPointsController.dispose();
    _redDoraCountController.dispose();
    _umaController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  void _initializeIfNeeded() {
    if (_initialized) return;
    _initialized = true;
    final ruleSetId = widget.ruleSetId;
    if (ruleSetId == null) return;
    final ruleSetAsync = ref.read(ruleSetByIdProvider(ruleSetId));
    ruleSetAsync.whenData((ruleSet) {
      if (ruleSet == null) return;
      _nameController.text = ruleSet.name;
      _descriptionController.text = ruleSet.description;
      _visibility = ruleSet.visibility;
      final rules = ruleSet.rules;
      if (rules != null) {
        _players = rules.players;
        _matchType = rules.matchType;
        _startingPointsController.text = rules.startingPoints.toString();
        _returnPointsController.text = rules.score.returnPoints.toString();
        _boxTenThreshold = rules.boxTenThreshold;
        _boxTenBehavior = rules.boxTenBehavior;
        _kuitan = rules.kuitan;
        _sakizuke = rules.sakizuke;
        _headBump = rules.headBump;
        _renchan = rules.renchan;
        _oorasuStop = rules.oorasuStop;
        _goRenchanTwoHan = rules.goRenchanTwoHan;
        _nagashiMangan = rules.nagashiMangan;
        _chiitoitsuFourTiles = rules.chiitoitsuFourTiles;
        _shaNyu = rules.shaNyu;
        _shaNyuOption = rules.shaNyuOption;
        _kandora = rules.kandora;
        _uradora = rules.uradora;
        _redDoraEnabled = rules.redDora.enabled;
        _redDoraCountController.text = rules.redDora.count.toString();
        _specialDora
          ..clear()
          ..addAll(rules.specialDora);
        _umaController.text = rules.score.uma;
        _riichiStick = rules.score.riichiStick;
        _yakumanMultiple = rules.yakuman.allowMultiple;
        _yakumanDouble = rules.yakuman.allowDouble;
        _threeNorthNuki = rules.threePlayer?.northNuki ?? true;
        _freeTextController.text = rules.freeText;
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initializeIfNeeded();
    final ruleSetId = widget.ruleSetId;
    final ruleSetAsync = ruleSetId == null
        ? null
        : ref.watch(ruleSetByIdProvider(ruleSetId));
    final ownerUidAsync = ref.watch(ownerUidProvider);

    return ruleSetAsync?.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('読み込みに失敗しました')),
            body: Center(child: Text(error.toString())),
          ),
          data: (ruleSet) {
            if (ruleSetId != null && ruleSet == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('ルールセットが見つかりません')),
                body: const Center(child: Text('指定されたルールセットは存在しません。')),
              );
            }
            if (ruleSetId != null) {
              return ownerUidAsync.when(
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Scaffold(
                  appBar: AppBar(title: const Text('読み込みに失敗しました。')),
                  body: Center(child: Text(error.toString())),
                ),
                data: (ownerUid) {
                  if (ruleSet?.ownerUid != ownerUid) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('編集できません。')),
                      body: const Center(
                        child: Text('オーナー以外はこのルールセットを編集できません。'),
                      ),
                    );
                  }
                  return _buildForm(context, 'ルールセット編集', ruleSet);
                },
              );
            }
            return _buildForm(context, 'ルールセット作成', ruleSet);
          },
        ) ??
        _buildForm(context, 'ルールセット作成', null);
  }

  Widget _buildForm(BuildContext context, String title, RuleSet? ruleSet) {
    final ownerNameAsync = ref.watch(ownerNameProvider);
    final ownerName = ownerNameAsync.asData?.value ?? ownerNameDefaultValue;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(ruleSet),
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ルールセット名'),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'オーナー名',
              helperText: '設定画面のオーナー名と同期されます。',
            ),
            child: Text(ownerName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '説明'),
          ),
          const SizedBox(height: 20),
          Text('公開設定', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('公開する'),
              subtitle: Text(
                _visibility == RuleSetVisibility.public
                    ? '共有コードが発行され、\n誰でも閲覧できます。'
                    : '自分の端末だけが閲覧できます。\n',
                maxLines: 2,
              ),
              value: _visibility == RuleSetVisibility.public,
              onChanged: (value) {
                setState(() {
                  _visibility = value
                      ? RuleSetVisibility.public
                      : RuleSetVisibility.private;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共有コードは一度公開すると変更されません。非公開に戻しても同じコードが使われます。削除すると破棄されます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text('対局形式・参加人数', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: '対局人数',
            child: _SegmentedPicker<PlayerCount>(
              value: _players,
              options: const {PlayerCount.four: '4人', PlayerCount.three: '3人'},
              onChanged: (value) {
                setState(() {
                  _players = value;
                  _applyDefaultPointsForPlayers();
                });
              },
            ),
          ),
          _RuleCard(
            title: '対局形式',
            child: _SegmentedPicker<MatchType>(
              value: _matchType,
              options: const {
                MatchType.tonpuu: '東風',
                MatchType.tonnan: '東南',
                MatchType.isshou: '一荘',
              },
              onChanged: (value) => setState(() => _matchType = value),
            ),
          ),
          _RuleCard(
            title: '持ち点',
            child: TextField(
              controller: _startingPointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: '点'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _RuleCard(
            title: '返し点',
            child: TextField(
              controller: _returnPointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: '点'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _RuleCard(
            title: 'オカ（自動計算）',
            child: Text(
              '${_calcOka()}点',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 20),
          Text('進行ルール（局の進行）', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: '食いタン',
            child: _SegmentedPicker<KuitanRule>(
              value: _kuitan,
              options: const {KuitanRule.on: 'あり', KuitanRule.off: 'なし'},
              onChanged: (value) => setState(() => _kuitan = value),
            ),
          ),
          _RuleCard(
            title: '先付け',
            child: DropdownButtonFormField<SakizukeRule>(
              value: _sakizuke,
              items: const [
                DropdownMenuItem(
                  value: SakizukeRule.complete,
                  child: Text('完全先付け'),
                ),
                DropdownMenuItem(value: SakizukeRule.ato, child: Text('後付け')),
                DropdownMenuItem(
                  value: SakizukeRule.naka,
                  child: Text('中付け（レア）'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sakizuke = value);
              },
            ),
          ),
          _RuleCard(
            title: '頭ハネ / ダブロン',
            child: _SegmentedPicker<HeadBumpRule>(
              value: _headBump,
              options: const {
                HeadBumpRule.atama: '頭ハネ',
                HeadBumpRule.daburon: 'ダブロン',
              },
              onChanged: (value) => setState(() => _headBump = value),
            ),
          ),
          _RuleCard(
            title: '連荘条件',
            child: _SegmentedPicker<RenchanRule>(
              value: _renchan,
              options: const {
                RenchanRule.oyaTenpai: '親テンパイ連荘',
                RenchanRule.oyaRyuukyoku: '親流局連荘',
              },
              onChanged: (value) => setState(() => _renchan = value),
            ),
          ),
          _RuleCard(
            title: '5本場以上2翻縛り',
            child: _SegmentedPicker<GoRenchanTwoHanRule>(
              value: _goRenchanTwoHan,
              options: const {
                GoRenchanTwoHanRule.on: 'あり',
                GoRenchanTwoHanRule.off: 'なし',
              },
              onChanged: (value) => setState(() => _goRenchanTwoHan = value),
            ),
          ),
          _RuleCard(
            title: '流し満貫',
            child: _SegmentedPicker<NagashiManganRule>(
              value: _nagashiMangan,
              options: const {
                NagashiManganRule.on: 'あり',
                NagashiManganRule.off: 'なし',
              },
              onChanged: (value) => setState(() => _nagashiMangan = value),
            ),
          ),
          _RuleCard(
            title: '七対子４枚使い',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SegmentedPicker<ChiitoitsuFourTilesRule>(
                  value: _chiitoitsuFourTiles,
                  options: const {
                    ChiitoitsuFourTilesRule.on: 'あり',
                    ChiitoitsuFourTilesRule.off: 'なし',
                  },
                  onChanged: (value) =>
                      setState(() => _chiitoitsuFourTiles = value),
                ),
              ],
            ),
          ),
          _RuleCard(
            title: '西入',
            child: _SegmentedPicker<ShaNyuRule>(
              value: _shaNyu,
              options: const {ShaNyuRule.on: 'あり', ShaNyuRule.off: 'なし'},
              onChanged: (value) => setState(() => _shaNyu = value),
            ),
          ),
          if (_shaNyu == ShaNyuRule.on)
            _RuleCard(
              title: '西入時の進行',
              child: _SegmentedPicker<ShaNyuOption>(
                value: _shaNyuOption,
                options: const {
                  ShaNyuOption.suddenDeath: 'サドンデス',
                  ShaNyuOption.untilWestRoundEnd: '西場終了まで続行',
                },
                onChanged: (value) => setState(() => _shaNyuOption = value),
              ),
            ),
          const SizedBox(height: 20),
          Text('ゲーム終了条件', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: '箱テン判定',
            child: _SegmentedPicker<BoxTenThreshold>(
              value: _boxTenThreshold,
              options: const {
                BoxTenThreshold.zero: '0点以下の時点',
                BoxTenThreshold.minus: 'マイナス時点',
              },
              onChanged: (value) => setState(() => _boxTenThreshold = value),
            ),
          ),
          _RuleCard(
            title: '箱テン後の扱い',
            child: _SegmentedPicker<BoxTenBehavior>(
              value: _boxTenBehavior,
              options: const {
                BoxTenBehavior.end: '終了',
                BoxTenBehavior.continuePlay: '続行',
              },
              onChanged: (value) => setState(() => _boxTenBehavior = value),
            ),
          ),
          _RuleCard(
            title: 'オーラス止め',
            child: _SegmentedPicker<OorasuStopRule>(
              value: _oorasuStop,
              options: const {
                OorasuStopRule.on: 'あり',
                OorasuStopRule.off: 'なし',
              },
              onChanged: (value) => setState(() => _oorasuStop = value),
            ),
          ),
          const SizedBox(height: 20),
          Text('ドラ設定', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: 'カンドラ',
            child: _SegmentedPicker<DoraRule>(
              value: _kandora,
              options: const {DoraRule.on: 'あり', DoraRule.off: 'なし'},
              onChanged: (value) => setState(() => _kandora = value),
            ),
          ),
          _RuleCard(
            title: '裏ドラ',
            child: _SegmentedPicker<DoraRule>(
              value: _uradora,
              options: const {DoraRule.on: 'あり', DoraRule.off: 'なし'},
              onChanged: (value) => setState(() => _uradora = value),
            ),
          ),
          _RuleCard(
            title: '赤ドラ',
            child: Row(
              children: [
                Switch(
                  value: _redDoraEnabled,
                  onChanged: (value) => setState(() => _redDoraEnabled = value),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _redDoraCountController,
                    enabled: _redDoraEnabled,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '枚数'),
                  ),
                ),
              ],
            ),
          ),
          _RuleCard(
            title: '特殊ドラ',
            child: Column(
              children: SpecialDora.values.map((dora) {
                final label = switch (dora) {
                  SpecialDora.gold => '金ドラ',
                  SpecialDora.hana => '花牌',
                  SpecialDora.nuki => '抜きドラ',
                };
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label),
                  value: _specialDora.contains(dora),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _specialDora.add(dora);
                      } else {
                        _specialDora.remove(dora);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          if (_players == PlayerCount.three)
            _RuleCard(
              title: '北抜き',
              child: _SegmentedPicker<bool>(
                value: _threeNorthNuki,
                options: const {true: 'あり', false: 'なし'},
                onChanged: (value) => setState(() => _threeNorthNuki = value),
              ),
            ),
          const SizedBox(height: 20),
          Text('得点配分（精算）', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: 'ウマ',
            child: TextField(
              controller: _umaController,
              decoration: const InputDecoration(hintText: '例: 20-10'),
            ),
          ),
          _RuleCard(
            title: 'リーチ棒の扱い',
            child: _SegmentedPicker<RiichiStickRule>(
              value: _riichiStick,
              options: const {
                RiichiStickRule.topTake: 'トップ総取り',
                RiichiStickRule.split: '分配',
              },
              onChanged: (value) => setState(() => _riichiStick = value),
            ),
          ),
          const SizedBox(height: 20),
          Text('役満・特殊扱い', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: '役満の扱い',
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('複合役満を認める'),
                  value: _yakumanMultiple,
                  onChanged: (value) =>
                      setState(() => _yakumanMultiple = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ダブル役満を認める'),
                  value: _yakumanDouble,
                  onChanged: (value) => setState(() => _yakumanDouble = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('自由入力', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _RuleCard(
            title: '自由入力欄',
            child: TextField(
              controller: _freeTextController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '独自のローカルルールなどを自由に記述できます。',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : () => _save(ruleSet),
            child: Text(_saving ? '保存中...' : '保存する'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(RuleSet? ruleSet) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ルールセット名を入力してください。')));
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final description = _descriptionController.text.trim();
      final ownerUid = await ref.read(ownerUidProvider.future);
      final repository = ref.read(ruleSetRepositoryProvider);
      final startingPoints =
          int.tryParse(_startingPointsController.text.trim()) ?? 25000;
      final returnPoints =
          int.tryParse(_returnPointsController.text.trim()) ?? 30000;
      final redDoraCount =
          int.tryParse(_redDoraCountController.text.trim()) ?? 0;
      final uma = _umaController.text.trim().isEmpty
          ? '20-10'
          : _umaController.text.trim();
      final players = _players == PlayerCount.three ? 3 : 4;
      final oka = (returnPoints - startingPoints) * players;

      final rules = RuleSetRules(
        players: _players,
        matchType: _matchType,
        startingPoints: startingPoints,
        boxTenThreshold: _boxTenThreshold,
        boxTenBehavior: _boxTenBehavior,
        kuitan: _kuitan,
        sakizuke: _sakizuke,
        headBump: _headBump,
        renchan: _renchan,
        oorasuStop: _oorasuStop,
        goRenchanTwoHan: _goRenchanTwoHan,
        nagashiMangan: _nagashiMangan,
        chiitoitsuFourTiles: _chiitoitsuFourTiles,
        shaNyu: _shaNyu,
        shaNyuOption: _shaNyuOption,
        kandora: _kandora,
        uradora: _uradora,
        redDora: RedDoraRule(
          enabled: _redDoraEnabled,
          count: _redDoraEnabled ? redDoraCount : 0,
        ),
        specialDora: _specialDora.toList(),
        score: ScoreRules(
          oka: oka,
          returnPoints: returnPoints,
          uma: uma,
          riichiStick: _riichiStick,
        ),
        yakuman: YakumanRules(
          allowMultiple: _yakumanMultiple,
          allowDouble: _yakumanDouble,
        ),
        threePlayer: _players == PlayerCount.three
            ? ThreePlayerRules(northNuki: _threeNorthNuki)
            : null,
        freeText: _freeTextController.text.trim(),
      );

      if (ruleSet == null) {
        final created = await repository.createRuleSet(
          name: name,
          description: description,
          ownerUid: ownerUid,
          visibility: _visibility,
          items: const [],
          rules: rules,
        );
        await repository.followRuleSet(
          ownerUid: ownerUid,
          ruleSetId: created.id,
        );
        if (!mounted) return;
        context.goNamed('ruleset-detail', pathParameters: {'id': created.id});
      } else {
        await repository.updateRuleSet(
          id: ruleSet.id,
          name: name,
          description: description,
          ownerUid: ruleSet.ownerUid ?? ownerUid,
          visibility: _visibility,
          items: ruleSet.items,
          shareCode: ruleSet.shareCode,
          rules: rules,
        );
        if (!mounted) return;
        context.goNamed('ruleset-detail', pathParameters: {'id': ruleSet.id});
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  int _calcOka() {
    final startingPoints =
        int.tryParse(_startingPointsController.text.trim()) ?? 25000;
    final returnPoints =
        int.tryParse(_returnPointsController.text.trim()) ?? 30000;
    final players = _players == PlayerCount.three ? 3 : 4;
    return (returnPoints - startingPoints) * players;
  }

  void _applyDefaultPointsForPlayers() {
    if (_players == PlayerCount.three) {
      _startingPointsController.text = '35000';
      _returnPointsController.text = '40000';
    } else {
      _startingPointsController.text = '25000';
      _returnPointsController.text = '30000';
    }
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _SegmentedPicker<T> extends StatelessWidget {
  const _SegmentedPicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: options.entries
          .map(
            (entry) =>
                ButtonSegment<T>(value: entry.key, label: Text(entry.value)),
          )
          .toList(),
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}
