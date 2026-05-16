import 'portfolio_position.dart';
import 'news_event.dart';
import 'candle.dart';

enum SimulationStatus { idle, playing, paused, completed }

class SimulationSession {
  final int? id;
  final String missionId;
  final String eraId;
  final String startDate;
  final String endDate;
  final double initialCash;
  final double currentCash;
  final List<String> selectedSymbols;
  final SimulationStatus status;

  const SimulationSession({
    this.id,
    required this.missionId,
    required this.eraId,
    required this.startDate,
    required this.endDate,
    required this.initialCash,
    required this.currentCash,
    required this.selectedSymbols,
    this.status = SimulationStatus.idle,
  });

  SimulationSession copyWith({
    double? currentCash,
    SimulationStatus? status,
  }) =>
      SimulationSession(
        id: id,
        missionId: missionId,
        eraId: eraId,
        startDate: startDate,
        endDate: endDate,
        initialCash: initialCash,
        currentCash: currentCash ?? this.currentCash,
        selectedSymbols: selectedSymbols,
        status: status ?? this.status,
      );
}

class SimulationState {
  final SimulationSession session;
  final Map<String, List<Candle>> allCandles; // symbol -> 全ローソク足
  final int currentIndex; // 現在の日付インデックス（全シンボル共通）
  final Map<String, PortfolioPosition> positions; // symbol -> ポジション
  final SimulationStatus playbackStatus;
  final int speedMultiplier; // 1, 3, 10
  final NewsEvent? activeNewsEvent;
  final List<double> portfolioValueHistory; // 日次資産推移

  const SimulationState({
    required this.session,
    required this.allCandles,
    this.currentIndex = 0,
    this.positions = const {},
    this.playbackStatus = SimulationStatus.paused,
    this.speedMultiplier = 1,
    this.activeNewsEvent,
    this.portfolioValueHistory = const [],
  });

  String? get currentDate {
    final firstSymbol = allCandles.keys.firstOrNull;
    if (firstSymbol == null) return null;
    final candles = allCandles[firstSymbol]!;
    if (currentIndex >= candles.length) return null;
    return candles[currentIndex].date;
  }

  Map<String, Candle> get currentCandles {
    final result = <String, Candle>{};
    for (final entry in allCandles.entries) {
      if (currentIndex < entry.value.length) {
        result[entry.key] = entry.value[currentIndex];
      }
    }
    return result;
  }

  double get totalStockValue => positions.values
      .fold(0, (sum, p) => sum + p.marketValue);

  double get totalAssetValue => session.currentCash + totalStockValue;

  double get totalReturnPct {
    if (session.initialCash == 0) return 0;
    return ((totalAssetValue - session.initialCash) / session.initialCash) * 100;
  }

  bool get isFinished {
    final firstSymbol = allCandles.keys.firstOrNull;
    if (firstSymbol == null) return true;
    return currentIndex >= (allCandles[firstSymbol]?.length ?? 0) - 1;
  }

  SimulationState copyWith({
    SimulationSession? session,
    int? currentIndex,
    Map<String, PortfolioPosition>? positions,
    SimulationStatus? playbackStatus,
    int? speedMultiplier,
    NewsEvent? activeNewsEvent,
    bool clearNewsEvent = false,
    List<double>? portfolioValueHistory,
  }) =>
      SimulationState(
        session: session ?? this.session,
        allCandles: allCandles,
        currentIndex: currentIndex ?? this.currentIndex,
        positions: positions ?? this.positions,
        playbackStatus: playbackStatus ?? this.playbackStatus,
        speedMultiplier: speedMultiplier ?? this.speedMultiplier,
        activeNewsEvent:
            clearNewsEvent ? null : (activeNewsEvent ?? this.activeNewsEvent),
        portfolioValueHistory:
            portfolioValueHistory ?? this.portfolioValueHistory,
      );
}
