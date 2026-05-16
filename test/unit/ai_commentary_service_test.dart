import 'package:flutter_test/flutter_test.dart';
import 'package:stock_simulator_kids/services/ai_commentary_service.dart';
import 'package:stock_simulator_kids/data/models/simulation_session.dart';
import 'package:stock_simulator_kids/data/models/candle.dart';

SimulationState _makeState({double returnPct = 0}) {
  final initial = 1000000.0;
  final current = initial * (1 + returnPct / 100);
  final session = SimulationSession(
    missionId: 'stage1',
    eraId: 'test',
    startDate: '2020-01-01',
    endDate: '2020-12-31',
    initialCash: initial,
    currentCash: current,
    selectedSymbols: const ['0001'],
  );
  return SimulationState(
    session: session,
    allCandles: {
      '0001': [Candle(date: '2020-01-01', close: 1000)]
    },
    portfolioValueHistory: [initial, current],
  );
}

void main() {
  final service = AiCommentaryService();

  group('AiCommentaryService', () {
    test('50%超のリターンで大成功コメントを返す', () {
      final state = _makeState(returnPct: 60);
      final commentary = service.generate(state, []);
      expect(commentary, contains('大成功'));
    });

    test('10〜50%のリターンでプラスコメントを返す', () {
      final state = _makeState(returnPct: 20);
      final commentary = service.generate(state, []);
      expect(commentary, contains('%のプラスで終了'));
    });

    test('0〜10%の微増でプラスフィニッシュコメントを返す', () {
      final state = _makeState(returnPct: 3);
      final commentary = service.generate(state, []);
      expect(commentary, contains('プラスフィニッシュ'));
    });

    test('-10〜0%の小幅損失でマイナスコメントを返す', () {
      final state = _makeState(returnPct: -5);
      final commentary = service.generate(state, []);
      expect(commentary, contains('授業料'));
    });

    test('-10%超の大幅損失で分散投資を勧めるコメントを返す', () {
      final state = _makeState(returnPct: -25);
      final commentary = service.generate(state, []);
      expect(commentary, contains('分散投資'));
    });

    test('iron_mind バッジを持つと鉄のメンタル言及がある', () {
      final state = _makeState(returnPct: 15);
      final commentary = service.generate(state, ['iron_mind']);
      expect(commentary, contains('鉄のメンタル'));
    });

    test('long_term_investor バッジを持つと長期保有への言及がある', () {
      final state = _makeState(returnPct: -5);
      final commentary = service.generate(state, ['long_term_investor']);
      expect(commentary, contains('一度も売らなかった'));
    });

    test('空のバッジリストでもクラッシュしない', () {
      final state = _makeState(returnPct: 0);
      expect(() => service.generate(state, []), returnsNormally);
    });
  });
}
