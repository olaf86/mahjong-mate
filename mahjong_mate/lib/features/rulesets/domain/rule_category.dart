enum RuleCategory {
  basic,
  scoring,
  yaku,
  adjudication,
}

extension RuleCategoryX on RuleCategory {
  String get label {
    switch (this) {
      case RuleCategory.basic:
        return '基本進行';
      case RuleCategory.scoring:
        return '得点計算';
      case RuleCategory.yaku:
        return '採用役・ローカル役';
      case RuleCategory.adjudication:
        return '細かい裁定';
    }
  }
}
