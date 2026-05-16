import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/simulation_session.dart';
import '../../../services/ai_commentary_service.dart';
import '../../../services/badge_service.dart';
import '../../providers/app_providers.dart';
import '../../providers/simulation_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const ResultScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _progressSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(simulationProvider(widget.sessionId)) == null) {
        ref
            .read(simulationProvider(widget.sessionId).notifier)
            .load(widget.sessionId, []);
      }
    });
  }

  Future<void> _saveProgressIfNeeded(
      SimulationState state, List<dynamic> tradeLogs) async {
    if (_progressSaved) return;
    _progressSaved = true;
    final badgeIds = BadgeService().evaluate(state, tradeLogs);
    await ref
        .read(missionRepositoryProvider)
        .markCompleted(state.session.missionId, badgeIds);
    // ミッションアンロック状態を再評価
    ref.invalidate(missionUnlockedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(simulationProvider(widget.sessionId));

    if (state == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('結果発表！')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tradeLogsAsync = ref.watch(tradeLogsProvider(widget.sessionId));
    final tradeLogs = tradeLogsAsync.valueOrNull ?? [];

    // 取引ログが揃ったらミッション進捗を保存（一回のみ）
    // build内の直接呼び出しを避けるためpostFrameCallbackで遅延実行
    if (tradeLogsAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveProgressIfNeeded(state, tradeLogs);
      });
    }

    final badgeService = BadgeService();
    final earnedBadgeIds = badgeService.evaluate(state, tradeLogs);
    final commentary = AiCommentaryService().generate(state, earnedBadgeIds);
    final returnPct = state.totalReturnPct;
    final isProfit = returnPct >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('結果発表！')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // リターンサマリー
            _ReturnSummaryCard(
              totalAsset: state.totalAssetValue,
              initialCash: state.session.initialCash,
              returnPct: returnPct,
              isProfit: isProfit,
            ),
            const SizedBox(height: 24),
            // 資産推移グラフ
            if (state.portfolioValueHistory.isNotEmpty)
              _PortfolioChartCard(history: state.portfolioValueHistory),
            const SizedBox(height: 24),
            // バッジ
            if (earnedBadgeIds.isNotEmpty)
              _BadgesCard(badgeIds: earnedBadgeIds),
            const SizedBox(height: 24),
            // AIコメント
            _AiCommentaryCard(commentary: commentary),
            const SizedBox(height: 32),
            // アクションボタン
            FilledButton.icon(
              onPressed: () => context.go('/missions'),
              icon: const Icon(Icons.replay),
              label: const Text('次のミッションへ', style: TextStyle(fontSize: 18)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/ranking'),
              icon: const Icon(Icons.leaderboard),
              label: const Text('ランキングを見る'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnSummaryCard extends StatelessWidget {
  final double totalAsset;
  final double initialCash;
  final double returnPct;
  final bool isProfit;

  const _ReturnSummaryCard({
    required this.totalAsset,
    required this.initialCash,
    required this.returnPct,
    required this.isProfit,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = totalAsset - initialCash;
    final color = isProfit ? AppColors.candleUp : AppColors.candleDown;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              isProfit ? '🎉 お疲れ様！' : '😅 お疲れ様！',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '${isProfit ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: '最終資産',
                  value: '¥${_fmt(totalAsset)}',
                  color: Colors.black,
                ),
                _Stat(
                  label: '損益',
                  value: '${isProfit ? '+' : ''}¥${_fmt(pnl)}',
                  color: color,
                ),
                _Stat(
                  label: '元手',
                  value: '¥${_fmt(initialCash)}',
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v.abs() >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}千万';
    if (v.abs() >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return v.toStringAsFixed(0);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _PortfolioChartCard extends StatelessWidget {
  final List<double> history;

  const _PortfolioChartCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('資産推移', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _LineChartPainter(values: history),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('開始', style: Theme.of(context).textTheme.bodySmall),
                Text('終了', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;

  _LineChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    if (range == 0) return;

    double toY(double v) => size.height - ((v - min) / range) * size.height * 0.9 - size.height * 0.05;

    final path = Path();
    final step = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = step * i;
      final y = toY(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 塗りつぶし
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final isProfit = values.last >= values.first;
    final color = isProfit ? AppColors.candleUp : AppColors.candleDown;

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.values != values;
}

class _BadgesCard extends StatelessWidget {
  final List<String> badgeIds;

  const _BadgesCard({required this.badgeIds});

  @override
  Widget build(BuildContext context) {
    final badges = badgeIds
        .map(BadgeService.findById)
        .whereType<Badge>()
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('獲得バッジ 🏅',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges
                  .map((b) => _BadgeChip(badge: b))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final Badge badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: badge.descriptionJa,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(badge.nameJa,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

class _AiCommentaryCard extends StatelessWidget {
  final String commentary;

  const _AiCommentaryCard({required this.commentary});

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Text('AIの分析',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                commentary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                    ),
              ),
            ],
          ),
        ),
      );
}
