import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stock_simulator_kids/data/datasources/local/app_database.dart';
import 'package:stock_simulator_kids/data/models/candle.dart';
import 'package:stock_simulator_kids/data/models/portfolio_position.dart';
import 'package:stock_simulator_kids/data/models/simulation_session.dart';
import 'package:stock_simulator_kids/data/repositories/price_repository.dart';
import 'package:stock_simulator_kids/presentation/providers/simulation_provider.dart';
import 'package:stock_simulator_kids/services/news_matcher_service.dart';
import 'package:stock_simulator_kids/data/models/news_event.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockPriceRepository extends Mock implements PriceRepository {}

// StateNotifier.state は @protected なので、テスト用サブクラスで初期状態を注入する
class _TestableNotifier extends SimulationNotifier {
  _TestableNotifier(super.db, super.priceRepo);
  void initState(SimulationState s) => state = s;
}

/// テスト用の基本 SimulationState を生成する
SimulationState _makeState({
  double cash = 1000000.0,
  Map<String, List<Candle>>? candles,
  Map<String, PortfolioPosition> positions = const {},
  int currentIndex = 0,
  int? sessionId,
}) {
  final allCandles = candles ??
      {
        '0001': [
          const Candle(date: '2020-01-06', close: 1000),
          const Candle(date: '2020-01-07', close: 1100),
          const Candle(date: '2020-01-08', close: 1050),
        ],
      };
  return SimulationState(
    session: SimulationSession(
      id: sessionId,
      missionId: 'stage1',
      eraId: 'test',
      startDate: '2020-01-01',
      endDate: '2020-12-31',
      initialCash: 1000000.0,
      currentCash: cash,
      selectedSymbols: allCandles.keys.toList(),
    ),
    allCandles: allCandles,
    currentIndex: currentIndex,
    positions: positions,
  );
}

void main() {
  late MockAppDatabase mockDb;
  late MockPriceRepository mockPriceRepo;
  late _TestableNotifier notifier;

  setUpAll(() {
    // mocktail: 非 null 型引数に any() を使うためのフォールバック登録
    registerFallbackValue(TradeLogTableCompanion.insert(
      sessionId: 0,
      symbol: '',
      tradeDate: '',
      side: '',
      shares: 0,
      price: 0.0,
      executedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ));
  });

  setUp(() {
    mockDb = MockAppDatabase();
    mockPriceRepo = MockPriceRepository();
    notifier = _TestableNotifier(mockDb, mockPriceRepo);
    // insertTradeLog のデフォルトスタブ（executeBuy/executeSell で呼ばれる）
    when(() => mockDb.insertTradeLog(any())).thenAnswer((_) async => 1);
  });

  group('SimulationNotifier.advanceDay', () {
    test('currentIndex が 1 増加する', () {
      notifier.initState(_makeState());
      notifier.advanceDay(null);
      expect(notifier.state!.currentIndex, 1);
    });

    test('ポジションの currentPrice が新しい終値に更新される', () {
      final pos = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 10,
        avgPrice: 1000,
        currentPrice: 1000,
      );
      notifier.initState(_makeState(positions: {'0001': pos}));
      notifier.advanceDay(null);
      // index=1 の終値は 1100
      expect(notifier.state!.positions['0001']!.currentPrice, 1100);
    });

    test('portfolioValueHistory に資産総額が追記される', () {
      notifier.initState(_makeState(cash: 500000, positions: {
        '0001': PortfolioPosition(
          symbol: '0001',
          companyNameJa: 'テスト',
          shares: 500,
          avgPrice: 1000,
          currentPrice: 1000,
        ),
      }));
      notifier.advanceDay(null);
      // 進んだ後: 現金 500,000 + 株価 1100 × 500 = 1,050,000
      expect(notifier.state!.portfolioValueHistory.last, closeTo(1050000, 1));
    });

    test('最終インデックスに達している場合は no-op', () {
      // candles が 3 本で currentIndex=2（最終）
      notifier.initState(_makeState(currentIndex: 2));
      notifier.advanceDay(null);
      expect(notifier.state!.currentIndex, 2); // 変化なし
    });

    test('ニュースイベントが日付に一致する場合 activeNewsEvent にセットされる', () {
      final newsEvent = NewsEvent(
        id: 'test_news',
        date: '2020-01-07',
        titleJa: 'テストニュース',
        bodyJa: '本文',
        impact: 'positive',
        affectedCategories: const ['all'],
        affectedSymbols: const [],
        emoji: '📰',
      );
      final matcher = NewsMatcherService([newsEvent]);
      notifier.initState(_makeState());
      notifier.advanceDay(matcher);
      expect(notifier.state!.activeNewsEvent?.id, 'test_news');
    });

    test('ニュースがない日は activeNewsEvent が null のまま', () {
      final matcher = NewsMatcherService([]);
      notifier.initState(_makeState());
      notifier.advanceDay(matcher);
      expect(notifier.state!.activeNewsEvent, isNull);
    });
  });

  group('SimulationNotifier.executeBuy', () {
    test('現金が減り、新規ポジションが作成される', () async {
      notifier.initState(_makeState(cash: 1000000, sessionId: null));
      await notifier.executeBuy('0001', 'テスト', 100, 1000);
      expect(notifier.state!.session.currentCash, 900000);
      expect(notifier.state!.positions['0001']!.shares, 100);
      expect(notifier.state!.positions['0001']!.avgPrice, 1000);
    });

    test('現金が不足している場合は no-op', () async {
      notifier.initState(_makeState(cash: 50000, sessionId: null));
      await notifier.executeBuy('0001', 'テスト', 100, 1000); // 10万必要
      expect(notifier.state!.session.currentCash, 50000); // 変化なし
      expect(notifier.state!.positions['0001'], isNull);
    });

    test('既存ポジションに追加買いすると平均取得単価が正しく計算される', () async {
      final existing = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 100,
        avgPrice: 1000,
        currentPrice: 1000,
      );
      notifier.initState(_makeState(cash: 1000000, positions: {'0001': existing}, sessionId: null));
      // 追加: 100株 × 1200円 = 120,000円
      await notifier.executeBuy('0001', 'テスト', 100, 1200);
      final pos = notifier.state!.positions['0001']!;
      expect(pos.shares, 200);
      // 平均 = (100*1000 + 100*1200) / 200 = 1100
      expect(pos.avgPrice, closeTo(1100, 0.01));
    });

    test('sessionId がある場合 insertTradeLog が呼ばれる', () async {
      notifier.initState(_makeState(cash: 1000000, sessionId: 99));
      await notifier.executeBuy('0001', 'テスト', 10, 1000);
      verify(() => mockDb.insertTradeLog(any())).called(1);
    });

    test('sessionId が null の場合 insertTradeLog は呼ばれない', () async {
      notifier.initState(_makeState(cash: 1000000, sessionId: null));
      await notifier.executeBuy('0001', 'テスト', 10, 1000);
      verifyNever(() => mockDb.insertTradeLog(any()));
    });
  });

  group('SimulationNotifier.executeSell', () {
    test('全株売却するとポジションが削除され現金が増える', () async {
      final pos = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 100,
        avgPrice: 1000,
        currentPrice: 1100,
      );
      notifier.initState(_makeState(cash: 0, positions: {'0001': pos}, sessionId: null));
      await notifier.executeSell('0001', 100, 1100);
      expect(notifier.state!.session.currentCash, 110000);
      expect(notifier.state!.positions['0001'], isNull);
    });

    test('一部売却するとシェア数が減り avgPrice はそのまま', () async {
      final pos = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 100,
        avgPrice: 1000,
        currentPrice: 1100,
      );
      notifier.initState(_makeState(cash: 0, positions: {'0001': pos}, sessionId: null));
      await notifier.executeSell('0001', 40, 1100);
      final remaining = notifier.state!.positions['0001']!;
      expect(remaining.shares, 60);
      expect(remaining.avgPrice, 1000); // avgPrice は変化しない
      expect(notifier.state!.session.currentCash, 44000); // 40 × 1100
    });

    test('保有していない銘柄の売却は no-op', () async {
      notifier.initState(_makeState(cash: 0, sessionId: null));
      await notifier.executeSell('9999', 10, 1000);
      expect(notifier.state!.session.currentCash, 0); // 変化なし
    });

    test('保有株数を超える売却は no-op', () async {
      final pos = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 50,
        avgPrice: 1000,
        currentPrice: 1000,
      );
      notifier.initState(_makeState(cash: 0, positions: {'0001': pos}, sessionId: null));
      await notifier.executeSell('0001', 100, 1000); // 100株 > 保有50株
      expect(notifier.state!.positions['0001']!.shares, 50); // 変化なし
    });

    test('sessionId がある場合 insertTradeLog が呼ばれる', () async {
      final pos = PortfolioPosition(
        symbol: '0001',
        companyNameJa: 'テスト',
        shares: 10,
        avgPrice: 1000,
        currentPrice: 1000,
      );
      notifier.initState(_makeState(positions: {'0001': pos}, sessionId: 99));
      await notifier.executeSell('0001', 10, 1000);
      verify(() => mockDb.insertTradeLog(any())).called(1);
    });
  });

  group('SimulationNotifier.dismissNews', () {
    test('activeNewsEvent が null にクリアされる', () {
      final newsEvent = NewsEvent(
        id: 'n1',
        date: '2020-01-06',
        titleJa: 'ニュース',
        bodyJa: '本文',
        impact: 'negative',
        affectedCategories: const ['all'],
        affectedSymbols: const [],
        emoji: '📉',
      );
      // activeNewsEvent をセットした状態を initState で注入
      notifier.initState(_makeState().copyWith(activeNewsEvent: newsEvent));
      expect(notifier.state!.activeNewsEvent, isNotNull);
      notifier.dismissNews();
      expect(notifier.state!.activeNewsEvent, isNull);
    });
  });
}
