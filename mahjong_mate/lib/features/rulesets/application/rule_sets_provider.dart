import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/rule_category.dart';
import '../domain/rule_item.dart';
import '../domain/rule_set.dart';

final ruleSetsProvider = Provider<List<RuleSet>>((ref) {
  return const [
    RuleSet(
      id: 'main-community',
      name: 'メインコミュニティ採用ルール',
      description: 'オンラインと雀荘で共有している標準ルールセット。',
      ownerName: 'Mahjong Mate',
      shareCode: 'MJM-2107',
      isPublic: true,
      items: [
        RuleItem(
          id: 'basic-1',
          category: RuleCategory.basic,
          title: '喰いタンあり・後付けなし',
          description: '鳴きタンは許可、後付けは不可。',
          priority: 2,
        ),
        RuleItem(
          id: 'basic-2',
          category: RuleCategory.basic,
          title: '赤ドラ3枚（5筒・5萬・5索）',
          description: '赤牌は各1枚、計3枚。',
        ),
        RuleItem(
          id: 'score-1',
          category: RuleCategory.scoring,
          title: '満貫切り上げあり',
          description: '3翻60符/4翻30符は満貫扱い。',
        ),
        RuleItem(
          id: 'yaku-1',
          category: RuleCategory.yaku,
          title: 'ダブル役満: 九蓮宝燈・四暗刻単騎',
          description: 'ダブル役満として扱う。',
        ),
        RuleItem(
          id: 'judge-1',
          category: RuleCategory.adjudication,
          title: 'チョンボ: 3000/6000',
          description: '子3000・親6000の支払い。',
        ),
      ],
    ),
    RuleSet(
      id: 'shop-stream',
      name: '雀荘配信用ルール',
      description: '店内掲示と配信用のわかりやすい簡易版。',
      ownerName: 'ひなた雀荘',
      shareCode: 'SHOP-5521',
      isPublic: true,
      items: [
        RuleItem(
          id: 'basic-3',
          category: RuleCategory.basic,
          title: '喰いタンあり・後付けあり',
          description: '初心者卓向けの設定。',
        ),
        RuleItem(
          id: 'score-2',
          category: RuleCategory.scoring,
          title: '切り上げなし',
          description: '翻と符の通りに計算。',
        ),
      ],
    ),
  ];
});

final ruleSetByIdProvider = Provider.family<RuleSet?, String>((ref, id) {
  final ruleSets = ref.watch(ruleSetsProvider);
  for (final ruleSet in ruleSets) {
    if (ruleSet.id == id) {
      return ruleSet;
    }
  }
  return null;
});
