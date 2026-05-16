import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/models/candle.dart';
import '../../data/models/portfolio_position.dart';
import '../../data/models/simulation_session.dart';
import '../../data/models/news_event.dart';
import '../../data/repositories/price_repository.dart';
import '../../services/news_matcher_service.dart';
import 'app_providers.dart';

// セッションID → SimulationState
final simulationProvider =
    StateNotifierProvider.family<SimulationNotifier, SimulationState?, int>(
  (ref, sessionId) => SimulationNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(priceRepositoryProvider),
  ),
);

class SimulationNotifier extends StateNotifier<SimulationState?> {
  final AppDatabase _db;
  final PriceRepository _priceRepo;
  Map<String, String> _companyCategories = {};
  bool _dcaEnabled = false;
  double _dcaMonthlyAmount = 0;

  SimulationNotifier(this._db, this._priceRepo) : super(null);

  Future<void> load(
    int sessionId,
    List<NewsEvent> allNewsEvents, {
    Map<String, String> companyNames = const {},
    Map<String, String> companyCategories = const {},
    bool dcaEnabled = false,
    double dcaMonthlyAmount = 0,
  }) async {
    _companyCategories = companyCategories;
    _dcaEnabled = dcaEnabled;
    _dcaMonthlyAmount = dcaMonthlyAmount;
    final session = await _db.getSession(sessionId);
    if (session == null) return;

    final symbols = (jsonDecode(session.selectedSymbolsJson) as List<dynamic>)
        .map((e) => e as String)
        .toList();

    final allCandles = <String, List<Candle>>{};
    for (final symbol in symbols) {
      final candles = await _priceRepo.getCandles(
        symbol,
        session.startDate,
        session.endDate,
      );
      allCandles[symbol] = candles;
    }

    final dbPositions = await _db.getPositions(sessionId);
    final positions = <String, PortfolioPosition>{};
    for (final p in dbPositions) {
      final currentCandles = allCandles[p.symbol];
      final currentPrice = currentCandles?.isNotEmpty == true
          ? currentCandles!.last.close
          : p.avgPrice;
      positions[p.symbol] = PortfolioPosition(
        symbol: p.symbol,
        companyNameJa: companyNames[p.symbol] ?? p.symbol,
        shares: p.shares,
        avgPrice: p.avgPrice,
        currentPrice: currentPrice,
      );
    }

    state = SimulationState(
      session: SimulationSession(
        id: session.id,
        missionId: session.missionId,
        eraId: session.eraId,
        startDate: session.startDate,
        endDate: session.endDate,
        initialCash: session.initialCash,
        currentCash: session.currentCash,
        selectedSymbols: symbols,
      ),
      allCandles: allCandles,
      positions: positions,
    );
  }

  void advanceDay(NewsMatcherService? newsMatcher) {
    final s = state;
    if (s == null || s.isFinished) return;

    final newIndex = s.currentIndex + 1;
    final currentCandles = <String, Candle>{};
    final newPositions = Map<String, PortfolioPosition>.from(s.positions);

    for (final entry in s.allCandles.entries) {
      if (newIndex < entry.value.length) {
        final candle = entry.value[newIndex];
        currentCandles[entry.key] = candle;
        if (newPositions.containsKey(entry.key)) {
          newPositions[entry.key] =
              newPositions[entry.key]!.copyWith(currentPrice: candle.close);
        }
      }
    }

    // DCA: 月が変わった最初の営業日に自動購入
    double newCash = s.session.currentCash;
    if (_dcaEnabled && _dcaMonthlyAmount > 0) {
      final prevDate = s.currentDate; // 前の日付
      final currDate = currentCandles.values.firstOrNull?.date;
      final isNewMonth = prevDate != null &&
          currDate != null &&
          currDate.substring(0, 7) != prevDate.substring(0, 7);
      if (isNewMonth) {
        final symbol = s.session.selectedSymbols.first;
        final candle = currentCandles[symbol];
        if (candle != null && candle.close > 0 && newCash >= candle.close) {
          final affordableAmount =
              newCash < _dcaMonthlyAmount ? newCash : _dcaMonthlyAmount;
          final shares = (affordableAmount / candle.close).floor();
          if (shares > 0) {
            final cost = shares * candle.close;
            final existing = newPositions[symbol];
            final totalShares = (existing?.shares ?? 0) + shares;
            final newAvgPrice = existing == null
                ? candle.close
                : (existing.costBasis + cost) / totalShares;
            newPositions[symbol] = PortfolioPosition(
              symbol: symbol,
              companyNameJa: existing?.companyNameJa ?? symbol,
              shares: totalShares,
              avgPrice: newAvgPrice,
              currentPrice: candle.close,
            );
            newCash -= cost;
          }
        }
      }
    }

    final totalValue = newCash +
        newPositions.values.fold(0.0, (sum, p) => sum + p.marketValue);
    final newHistory = [...s.portfolioValueHistory, totalValue];

    // ニュースイベント照合（複数銘柄の場合は最初にマッチしたものを表示）
    final date = currentCandles.values.firstOrNull?.date;
    NewsEvent? newsEvent;
    if (newsMatcher != null && date != null) {
      for (final symbol in s.session.selectedSymbols) {
        final category = _companyCategories[symbol] ?? '';
        final found = newsMatcher.findForDate(date, symbol, category);
        if (found != null) {
          newsEvent = found;
          break;
        }
      }
    }

    state = s.copyWith(
      currentIndex: newIndex,
      session: newCash != s.session.currentCash
          ? s.session.copyWith(currentCash: newCash)
          : null,
      positions: newPositions,
      portfolioValueHistory: newHistory,
      activeNewsEvent: newsEvent,
    );
  }

  void setPlaybackStatus(SimulationStatus status) {
    if (state == null) return;
    state = state!.copyWith(playbackStatus: status);
  }

  void dismissNews() {
    if (state == null) return;
    state = state!.copyWith(clearNewsEvent: true);
  }

  Future<void> executeBuy(
    String symbol,
    String companyName,
    int shares,
    double price,
  ) async {
    final s = state;
    if (s == null) return;

    final cost = shares * price;
    if (cost > s.session.currentCash) return;

    final existing = s.positions[symbol];
    final totalShares = (existing?.shares ?? 0) + shares;
    final newAvgPrice = existing == null
        ? price
        : (existing.costBasis + cost) / totalShares;

    final newPositions = Map<String, PortfolioPosition>.from(s.positions);
    newPositions[symbol] = PortfolioPosition(
      symbol: symbol,
      companyNameJa: companyName,
      shares: totalShares,
      avgPrice: newAvgPrice,
      currentPrice: price,
    );

    final newCash = s.session.currentCash - cost;
    state = s.copyWith(
      session: s.session.copyWith(currentCash: newCash),
      positions: newPositions,
    );

    // DB に取引ログ保存
    if (s.session.id != null) {
      await _db.insertTradeLog(TradeLogTableCompanion.insert(
        sessionId: s.session.id!,
        symbol: symbol,
        tradeDate: s.currentDate ?? '',
        side: 'buy',
        shares: shares,
        price: price,
        executedAt: DateTime.now(),
      ));
    }
  }

  Future<void> executeSell(
    String symbol,
    int shares,
    double price,
  ) async {
    final s = state;
    if (s == null) return;

    if (shares <= 0) return;
    final existing = s.positions[symbol];
    if (existing == null || existing.shares < shares) return;

    final proceeds = shares * price;
    final remainingShares = existing.shares - shares;

    final newPositions = Map<String, PortfolioPosition>.from(s.positions);
    if (remainingShares <= 0) {
      newPositions.remove(symbol);
    } else {
      newPositions[symbol] = PortfolioPosition(
        symbol: symbol,
        companyNameJa: existing.companyNameJa,
        shares: remainingShares,
        avgPrice: existing.avgPrice,
        currentPrice: price,
      );
    }

    final newCash = s.session.currentCash + proceeds;
    state = s.copyWith(
      session: s.session.copyWith(currentCash: newCash),
      positions: newPositions,
    );

    if (s.session.id != null) {
      await _db.insertTradeLog(TradeLogTableCompanion.insert(
        sessionId: s.session.id!,
        symbol: symbol,
        tradeDate: s.currentDate ?? '',
        side: 'sell',
        shares: shares,
        price: price,
        executedAt: DateTime.now(),
      ));
    }
  }
}
