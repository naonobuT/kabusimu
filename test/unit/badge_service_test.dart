import 'package:flutter_test/flutter_test.dart';
import 'package:stock_simulator_kids/services/badge_service.dart';
import 'package:stock_simulator_kids/data/models/simulation_session.dart';
import 'package:stock_simulator_kids/data/models/candle.dart';
import 'package:stock_simulator_kids/data/models/portfolio_position.dart';

SimulationState _makeState({
  double returnPct = 0,
  List<double> history = const [],
  Map<String, PortfolioPosition> positions = const {},
  String missionId = 'stage1',
  List<String> symbols = const ['0001'],
}) {
  final initial = 1000000.0;
  final current = initial * (1 + returnPct / 100);
  final session = SimulationSession(
    missionId: missionId,
    eraId: 'test',
    startDate: '2020-01-01',
    endDate: '2020-12-31',
    initialCash: initial,
    currentCash: current,
    selectedSymbols: symbols,
  );
  return SimulationState(
    session: session,
    allCandles: {'0001': [Candle(date: '2020-01-01', close: 1000)]},
    positions: positions,
    portfolioValueHistory: history.isEmpty ? [initial, current] : history,
  );
}

void main() {
  final service = BadgeService();

  group('BadgeService', () {
    test('プラスリターンで positive_return バッジを取得', () {
      final state = _makeState(returnPct: 10);
      final badges = service.evaluate(state, []);
      expect(badges, contains('positive_return'));
    });

    test('マイナスリターンでは positive_return バッジを取得しない', () {
      final state = _makeState(returnPct: -5);
      final badges = service.evaluate(state, []);
      expect(badges, isNot(contains('positive_return')));
    });

    test('売り取引なしで long_term_investor バッジを取得', () {
      final state = _makeState(returnPct: 5);
      final badges = service.evaluate(state, []); // 売り取引なし
      expect(badges, contains('long_term_investor'));
    });

    test('売り取引があると long_term_investor バッジを取得しない', () {
      final state = _makeState(returnPct: 5);
      final tradeLogs = [{'side': 'sell', 'index': 1}];
      final badges = service.evaluate(state, tradeLogs);
      expect(badges, isNot(contains('long_term_investor')));
    });

    test('3社選択で diversification_master バッジを取得', () {
      final state = _makeState(
        symbols: ['0001', '7974', '6758'],
        returnPct: 0,
      );
      final badges = service.evaluate(state, []);
      expect(badges, contains('diversification_master'));
    });

    test('stage3 完走で dca_king バッジを取得', () {
      final state = _makeState(missionId: 'stage3', returnPct: 0);
      final badges = service.evaluate(state, []);
      expect(badges, contains('dca_king'));
    });

    test('20%超の暴落を耐えると iron_mind バッジを取得', () {
      // peak=120, bottom=90 → drawdown = 25% > 20%
      final history = [
        100.0, 110.0, 120.0, // ピーク
        100.0, 90.0,         // 25%下落
        95.0, 105.0,         // 回復
      ];
      final state = _makeState(history: history, returnPct: 5);
      final badges = service.evaluate(state, []); // 売り取引なし
      expect(badges, contains('iron_mind'));
    });

    test('BadgeService.findById は正しいバッジを返す', () {
      final badge = BadgeService.findById('long_term_investor');
      expect(badge, isNotNull);
      expect(badge!.emoji, '🌳');
    });

    test('存在しないIDは null を返す', () {
      expect(BadgeService.findById('nonexistent'), isNull);
    });
  });
}
