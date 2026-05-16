import '../data/models/simulation_session.dart';

class Badge {
  final String id;
  final String emoji;
  final String nameJa;
  final String descriptionJa;

  const Badge({
    required this.id,
    required this.emoji,
    required this.nameJa,
    required this.descriptionJa,
  });
}

class BadgeService {
  static const List<Badge> allBadges = [
    Badge(
      id: 'long_term_investor',
      emoji: '🌳',
      nameJa: '長期投資家',
      descriptionJa: '一度も売らずにシミュレーションを完走した',
    ),
    Badge(
      id: 'iron_mind',
      emoji: '🧠',
      nameJa: '鉄のメンタル',
      descriptionJa: '20%以上の暴落中も売らずに耐えた',
    ),
    Badge(
      id: 'diversification_master',
      emoji: '⚖️',
      nameJa: '分散の達人',
      descriptionJa: '3社以上に分散投資した',
    ),
    Badge(
      id: 'dca_king',
      emoji: '📅',
      nameJa: '積立王',
      descriptionJa: 'ドルコスト平均法シナリオを完走した',
    ),
    Badge(
      id: 'timing_genius',
      emoji: '🎯',
      nameJa: 'タイミング名人',
      descriptionJa: '底値の5%以内で株を購入した（運も実力のうち！）',
    ),
    Badge(
      id: 'positive_return',
      emoji: '📈',
      nameJa: 'プラス運用',
      descriptionJa: '最終的に利益を出してシミュレーションを終えた',
    ),
  ];

  List<String> evaluate(SimulationState finalState, List<dynamic> tradeLogs) {
    final earned = <String>[];

    // プラス運用
    if (finalState.totalReturnPct > 0) {
      earned.add('positive_return');
    }

    // 長期投資家: 売り取引がゼロ
    final hasSell = tradeLogs.any((t) => (t['side'] as String) == 'sell');
    if (!hasSell) earned.add('long_term_investor');

    // 分散の達人: 3社以上のポジションを持ったことがある
    if (finalState.session.selectedSymbols.length >= 3) {
      earned.add('diversification_master');
    }

    // DCA完走
    if (finalState.session.missionId == 'stage3') {
      earned.add('dca_king');
    }

    // 鉄のメンタル: 最大ドローダウン計算
    final history = finalState.portfolioValueHistory;
    if (history.length > 1) {
      double peak = history[0];
      double maxDrawdown = 0;
      bool heldThrough = true;
      for (int i = 1; i < history.length; i++) {
        if (history[i] > peak) peak = history[i];
        final dd = (peak - history[i]) / peak;
        if (dd > maxDrawdown) maxDrawdown = dd;
        // 暴落20%超えのタイミングで売っていないか確認
        if (dd >= 0.20) {
          final tradeOnDay = tradeLogs.any((t) => t['index'] == i && t['side'] == 'sell');
          if (tradeOnDay) { heldThrough = false; break; }
        }
      }
      if (maxDrawdown >= 0.20 && heldThrough) earned.add('iron_mind');
    }

    return earned;
  }

  static Badge? findById(String id) {
    try {
      return allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
