enum PlayerCount {
  four,
  three,
}

enum MatchType {
  tonpuu,
  tonnan,
  isshou,
}

enum BoxTenThreshold {
  zero,
  minus,
}

enum BoxTenBehavior {
  end,
  continuePlay,
}

enum KuitanRule {
  on,
  off,
}

enum SakizukeRule {
  complete,
  ato,
  naka,
}

enum HeadBumpRule {
  atama,
  daburon,
}

enum RenchanRule {
  oyaTenpai,
  oyaRyuukyoku,
}

enum OorasuStopRule {
  on,
  off,
}

enum GoRenchanTwoHanRule {
  on,
  off,
}

enum DoraRule {
  on,
  off,
}

enum SpecialDora {
  gold,
  hana,
  nuki,
}

enum RiichiStickRule {
  topTake,
  split,
}

class RedDoraRule {
  const RedDoraRule({
    required this.enabled,
    required this.count,
  });

  final bool enabled;
  final int count;
}

class ScoreRules {
  const ScoreRules({
    required this.oka,
    required this.returnPoints,
    required this.uma,
    required this.riichiStick,
  });

  final int oka;
  final int returnPoints;
  final String uma;
  final RiichiStickRule riichiStick;
}

class YakumanRules {
  const YakumanRules({
    required this.allowMultiple,
    required this.allowDouble,
  });

  final bool allowMultiple;
  final bool allowDouble;
}

class ThreePlayerRules {
  const ThreePlayerRules({
    required this.northNuki,
  });

  final bool northNuki;
}

class RuleSetRules {
  const RuleSetRules({
    required this.players,
    required this.matchType,
    required this.startingPoints,
    required this.boxTenThreshold,
    required this.boxTenBehavior,
    required this.kuitan,
    required this.sakizuke,
    required this.headBump,
    required this.renchan,
    required this.oorasuStop,
    required this.goRenchanTwoHan,
    required this.kandora,
    required this.uradora,
    required this.redDora,
    required this.specialDora,
    required this.score,
    required this.yakuman,
    required this.threePlayer,
  });

  final PlayerCount players;
  final MatchType matchType;
  final int startingPoints;
  final BoxTenThreshold boxTenThreshold;
  final BoxTenBehavior boxTenBehavior;
  final KuitanRule kuitan;
  final SakizukeRule sakizuke;
  final HeadBumpRule headBump;
  final RenchanRule renchan;
  final OorasuStopRule oorasuStop;
  final GoRenchanTwoHanRule goRenchanTwoHan;
  final DoraRule kandora;
  final DoraRule uradora;
  final RedDoraRule redDora;
  final List<SpecialDora> specialDora;
  final ScoreRules score;
  final YakumanRules yakuman;
  final ThreePlayerRules? threePlayer;

  Map<String, dynamic> toMap() {
    return {
      'players': players.name,
      'matchType': matchType.name,
      'startingPoints': startingPoints,
      'boxTenThreshold': boxTenThreshold.name,
      'boxTenBehavior': boxTenBehavior.name,
      'kuitan': kuitan.name,
      'sakizuke': sakizuke.name,
      'headBump': headBump.name,
      'renchan': renchan.name,
      'oorasuStop': oorasuStop.name,
      'goRenchanTwoHan': goRenchanTwoHan.name,
      'kandora': kandora.name,
      'uradora': uradora.name,
      'redDora': {
        'enabled': redDora.enabled,
        'count': redDora.count,
      },
      'specialDora': specialDora.map((item) => item.name).toList(),
      'score': {
        'oka': score.oka,
        'returnPoints': score.returnPoints,
        'uma': score.uma,
        'riichiStick': score.riichiStick.name,
      },
      'yakuman': {
        'allowMultiple': yakuman.allowMultiple,
        'allowDouble': yakuman.allowDouble,
      },
      if (threePlayer != null)
        'threePlayer': {
          'northNuki': threePlayer!.northNuki,
        },
    };
  }

  static RuleSetRules? fromMap(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    return RuleSetRules(
      players: _enumByName(PlayerCount.values, value['players'], PlayerCount.four),
      matchType: _enumByName(MatchType.values, value['matchType'], MatchType.tonpuu),
      startingPoints: _intValue(value['startingPoints'], fallback: 25000),
      boxTenThreshold: _enumByName(
        BoxTenThreshold.values,
        value['boxTenThreshold'],
        BoxTenThreshold.zero,
      ),
      boxTenBehavior: _enumByName(
        BoxTenBehavior.values,
        value['boxTenBehavior'],
        BoxTenBehavior.end,
      ),
      kuitan: _enumByName(KuitanRule.values, value['kuitan'], KuitanRule.on),
      sakizuke: _enumByName(SakizukeRule.values, value['sakizuke'], SakizukeRule.complete),
      headBump: _enumByName(HeadBumpRule.values, value['headBump'], HeadBumpRule.atama),
      renchan: _enumByName(RenchanRule.values, value['renchan'], RenchanRule.oyaTenpai),
      oorasuStop: _enumByName(OorasuStopRule.values, value['oorasuStop'], OorasuStopRule.on),
      goRenchanTwoHan:
          _enumByName(GoRenchanTwoHanRule.values, value['goRenchanTwoHan'], GoRenchanTwoHanRule.off),
      kandora: _enumByName(DoraRule.values, value['kandora'], DoraRule.on),
      uradora: _enumByName(DoraRule.values, value['uradora'], DoraRule.on),
      redDora: _parseRedDora(value['redDora']),
      specialDora: _parseSpecialDora(value['specialDora']),
      score: _parseScore(value['score']),
      yakuman: _parseYakuman(value['yakuman']),
      threePlayer: _parseThreePlayer(value['threePlayer']),
    );
  }

  static RedDoraRule _parseRedDora(Object? value) {
    if (value is Map<String, dynamic>) {
      final enabled = value['enabled'] == true;
      final count = _intValue(value['count'], fallback: enabled ? 3 : 0);
      return RedDoraRule(enabled: enabled, count: count);
    }
    return const RedDoraRule(enabled: true, count: 3);
  }

  static List<SpecialDora> _parseSpecialDora(Object? value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((name) => _enumByName(SpecialDora.values, name, SpecialDora.gold))
          .toSet()
          .toList();
    }
    return const [];
  }

  static ScoreRules _parseScore(Object? value) {
    if (value is Map<String, dynamic>) {
      return ScoreRules(
        oka: _intValue(value['oka'], fallback: 0),
        returnPoints: _intValue(value['returnPoints'], fallback: 30000),
        uma: (value['uma'] as String?)?.trim().isNotEmpty == true
            ? value['uma'] as String
            : '20-10',
        riichiStick: _enumByName(
          RiichiStickRule.values,
          value['riichiStick'],
          RiichiStickRule.topTake,
        ),
      );
    }
    return const ScoreRules(
      oka: 0,
      returnPoints: 30000,
      uma: '20-10',
      riichiStick: RiichiStickRule.topTake,
    );
  }

  static YakumanRules _parseYakuman(Object? value) {
    if (value is Map<String, dynamic>) {
      return YakumanRules(
        allowMultiple: value['allowMultiple'] == true,
        allowDouble: value['allowDouble'] == true,
      );
    }
    return const YakumanRules(allowMultiple: true, allowDouble: true);
  }

  static ThreePlayerRules? _parseThreePlayer(Object? value) {
    if (value is Map<String, dynamic>) {
      return ThreePlayerRules(
        northNuki: value['northNuki'] == true,
      );
    }
    return null;
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) {
          return value;
        }
      }
    }
    return fallback;
  }

  static int _intValue(Object? raw, {required int fallback}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return fallback;
  }
}
