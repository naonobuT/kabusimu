import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/company.dart';
import '../../../data/models/news_event.dart';
import '../../../data/models/simulation_session.dart';
import '../../../services/news_matcher_service.dart';
import '../../../services/simulation_engine.dart';
import '../../providers/app_providers.dart';
import '../../providers/simulation_provider.dart';
import 'widgets/candlestick_chart_widget.dart';
import 'widgets/news_popup_overlay.dart';
import 'widgets/playback_controls.dart';
import 'widgets/portfolio_panel.dart';
import 'dialogs/buy_dialog.dart';
import 'dialogs/sell_dialog.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const SimulationScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  late SimulationEngine _engine;
  NewsMatcherService? _newsMatcher;
  bool _initialized = false;
  String _selectedSymbol = '';
  String? _noDataSymbol;
  Map<String, Company> _companies = {};
  bool _wasPlayingWhenNewsFired = false;

  @override
  void initState() {
    super.initState();
    _engine = SimulationEngine(
      onTick: (_) => _onTick(),
      onFinished: _onFinished,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // Load news events（ファイル不在・破損でもクラッシュしない）
    List<NewsEvent> events = [];
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/news_events.json');
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        events = decoded
            .whereType<Map<String, dynamic>>()
            .map(NewsEvent.fromJson)
            .toList();
      }
    } catch (_) {}
    _newsMatcher = NewsMatcherService(events);

    // Load all companies for name lookup
    final allCompanies = await ref.read(companyRepositoryProvider).getAll();
    _companies = {for (final c in allCompanies) c.symbol: c};

    // Load mission config for DCA settings
    final missions = await ref.read(missionsProvider.future);
    final session =
        await ref.read(appDatabaseProvider).getSession(widget.sessionId);
    // missions が空のとき missions.first で StateError になるのを防ぐ
    final mission = missions.isNotEmpty
        ? missions.firstWhere(
            (m) => m.id == (session?.missionId ?? ''),
            orElse: () => missions.first,
          )
        : null;

    // Load simulation state via notifier (pass names + categories)
    final nameMap = {
      for (final e in _companies.entries) e.key: e.value.nameJa
    };
    final categoryMap = {
      for (final e in _companies.entries) e.key: e.value.category
    };
    await ref
        .read(simulationProvider(widget.sessionId).notifier)
        .load(widget.sessionId, events,
            companyNames: nameMap,
            companyCategories: categoryMap,
            dcaEnabled: mission?.dcaEnabled ?? false,
            dcaMonthlyAmount: mission?.dcaMonthlyAmount?.toDouble() ?? 0);

    final state = ref.read(simulationProvider(widget.sessionId));
    if (state != null && mounted) {
      _selectedSymbol = state.session.selectedSymbols.first;
      final candleCount = state.allCandles[_selectedSymbol]?.length ?? 0;
      if (candleCount == 0) {
        setState(() => _noDataSymbol = _selectedSymbol);
        return;
      }
      _engine.init(candleCount, startIndex: state.currentIndex);
      setState(() => _initialized = true);
    }
  }

  void _onTick() {
    final notifier =
        ref.read(simulationProvider(widget.sessionId).notifier);
    notifier.advanceDay(_newsMatcher);

    final state = ref.read(simulationProvider(widget.sessionId));
    // Pause engine when a news event fires (notifier already set activeNewsEvent)
    if (state?.activeNewsEvent != null) {
      _wasPlayingWhenNewsFired = !_engine.isPaused;
      _engine.pause();
      notifier.setPlaybackStatus(SimulationStatus.paused);
    }
    if (state?.isFinished == true) {
      _engine.pause();
    }
  }

  Future<void> _onFinished() async {
    final notifier =
        ref.read(simulationProvider(widget.sessionId).notifier);
    notifier.setPlaybackStatus(SimulationStatus.completed);

    // Mark session completed in DB — save total asset (cash + stocks) for ranking
    final finalState = ref.read(simulationProvider(widget.sessionId));
    await ref.read(appDatabaseProvider).markSessionCompleted(
      widget.sessionId,
      finalTotalAsset: finalState?.totalAssetValue,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/result/${widget.sessionId}');
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider(widget.sessionId));

    if (_noDataSymbol != null) {
      final name = _companies[_noDataSymbol]?.nameJa ?? _noDataSymbol!;
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12122A),
          foregroundColor: Colors.white,
          title: const Text('データがありません', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_download_outlined,
                    size: 64, color: Colors.white38),
                const SizedBox(height: 24),
                Text(
                  '「$name」の株価データが\nまだ読み込まれていません。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'J-Quantsデータのインポート画面から\nCSVファイルを読み込んでください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/import'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('データを読み込む'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('戻る',
                      style: TextStyle(color: Colors.white60)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized || state == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final symbols = state.session.selectedSymbols;
    final candles = state.allCandles[_selectedSymbol] ?? [];
    final visibleCount =
        (state.currentIndex + 1).clamp(1, candles.length);
    final visibleCandles = candles.sublist(0, visibleCount);

    final company = _companies[_selectedSymbol];
    final companyName = company?.nameJa ?? _selectedSymbol;

    final currentPrice = state.currentIndex < candles.length
        ? candles[state.currentIndex].close
        : 0.0;
    final canBuy = currentPrice > 0 && state.session.currentCash >= currentPrice;

    return Scaffold(
      backgroundColor: AppColors.chartBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        foregroundColor: Colors.white,
        title: Text(
          companyName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              state.currentDate ?? '',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 複数銘柄のシンボルセレクター
              if (symbols.length > 1)
                _SymbolSelector(
                  symbols: symbols,
                  companies: _companies,
                  selected: _selectedSymbol,
                  onSelected: (s) => setState(() => _selectedSymbol = s),
                ),
              // チャートエリア
              Expanded(
                child: Container(
                  color: AppColors.chartBackground,
                  child: CandlestickChartWidget(candles: visibleCandles),
                ),
              ),
              // ポートフォリオパネル
              PortfolioPanel(state: state),
              // 再生コントロール
              PlaybackControls(
                status: state.playbackStatus,
                speedMultiplier: _engine.speedMultiplier,
                currentDate: state.currentDate,
                newsActive: state.activeNewsEvent != null,
                onPlayPause: () {
                  _engine.togglePlayPause(state.currentIndex);
                  ref
                      .read(simulationProvider(widget.sessionId).notifier)
                      .setPlaybackStatus(
                        _engine.isPaused
                            ? SimulationStatus.paused
                            : SimulationStatus.playing,
                      );
                },
                onSpeedChange: () {
                  _engine.cycleSpeed();
                  setState(() {});
                },
                onSkip: () => _engine.skipMonth(),
              ),
              // 売買ボタン
              _TradeButtons(
                onBuy: () => _showBuyDialog(state, company),
                onSell: () => _showSellDialog(state, company),
                canBuy: canBuy,
                canSell: state.positions.containsKey(_selectedSymbol),
              ),
            ],
          ),
          // ニュースオーバーレイ
          NewsPopupOverlay(
            newsEvent: state.activeNewsEvent,
            onDismissed: () {
              ref
                  .read(simulationProvider(widget.sessionId).notifier)
                  .dismissNews();
              // ニュース発火前に再生中だった場合のみ再開
              if (_wasPlayingWhenNewsFired) {
                _wasPlayingWhenNewsFired = false;
                _engine.play(state.currentIndex);
                ref
                    .read(simulationProvider(widget.sessionId).notifier)
                    .setPlaybackStatus(SimulationStatus.playing);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showBuyDialog(SimulationState state, Company? company) async {
    _engine.pause();
    ref
        .read(simulationProvider(widget.sessionId).notifier)
        .setPlaybackStatus(SimulationStatus.paused);

    final candles = state.allCandles[_selectedSymbol] ?? [];
    if (candles.isEmpty || state.currentIndex >= candles.length) return;
    final currentPrice = candles[state.currentIndex].close;

    await showDialog(
      context: context,
      builder: (_) => BuyDialog(
        companyName: company?.nameJa ?? _selectedSymbol,
        currentPrice: currentPrice,
        availableCash: state.session.currentCash,
        onConfirm: (shares) {
          ref
              .read(simulationProvider(widget.sessionId).notifier)
              .executeBuy(
                _selectedSymbol,
                company?.nameJa ?? _selectedSymbol,
                shares,
                currentPrice,
              );
        },
      ),
    );
  }

  Future<void> _showSellDialog(SimulationState state, Company? company) async {
    _engine.pause();
    ref
        .read(simulationProvider(widget.sessionId).notifier)
        .setPlaybackStatus(SimulationStatus.paused);

    final position = state.positions[_selectedSymbol];
    if (position == null) return;

    await showDialog(
      context: context,
      builder: (_) => SellDialog(
        companyName: company?.nameJa ?? _selectedSymbol,
        currentPrice: position.currentPrice,
        sharesHeld: position.shares,
        onConfirm: (shares) {
          ref
              .read(simulationProvider(widget.sessionId).notifier)
              .executeSell(
                _selectedSymbol,
                shares,
                position.currentPrice,
              );
        },
      ),
    );
  }
}

class _SymbolSelector extends StatelessWidget {
  final List<String> symbols;
  final Map<String, Company> companies;
  final String selected;
  final ValueChanged<String> onSelected;

  const _SymbolSelector({
    required this.symbols,
    required this.companies,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: symbols.map((s) {
          final name = companies[s]?.nameJa ?? s;
          final isSelected = s == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white12,
              onSelected: (_) => onSelected(s),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TradeButtons extends StatelessWidget {
  final VoidCallback onBuy;
  final VoidCallback onSell;
  final bool canBuy;
  final bool canSell;

  const _TradeButtons({
    required this.onBuy,
    required this.onSell,
    required this.canBuy,
    required this.canSell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: canBuy ? onBuy : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.candleUp,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('買う', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: canSell ? onSell : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.candleDown,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.sell),
              label: const Text('売る', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
