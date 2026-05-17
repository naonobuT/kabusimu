import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';

final _rankingProvider =
    FutureProvider<List<_RankingEntry>>((ref) async {
  final db = ref.read(appDatabaseProvider);
  final sessions = await db.getCompletedSessions();

  return sessions.map((s) {
    final symbols = (jsonDecode(s.selectedSymbolsJson) as List).cast<String>();
    final returnPct = s.initialCash > 0
        ? ((s.currentCash - s.initialCash) / s.initialCash) * 100
        : 0.0;
    return _RankingEntry(
      sessionId: s.id,
      missionId: s.missionId,
      eraId: s.eraId,
      symbols: symbols,
      initialCash: s.initialCash,
      finalCash: s.currentCash,
      returnPct: returnPct,
      completedAt: s.updatedAt,
    );
  }).toList()
    ..sort((a, b) => b.returnPct.compareTo(a.returnPct));
});

class _RankingEntry {
  final int sessionId;
  final String missionId;
  final String eraId;
  final List<String> symbols;
  final double initialCash;
  final double finalCash;
  final double returnPct;
  final DateTime completedAt;

  _RankingEntry({
    required this.sessionId,
    required this.missionId,
    required this.eraId,
    required this.symbols,
    required this.initialCash,
    required this.finalCash,
    required this.returnPct,
    required this.completedAt,
  });
}

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(_rankingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ランキング')),
      body: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RankingCard(
              rank: i + 1,
              entry: entries[i],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'まだ記録がありません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'シミュレーションを完了するとここに結果が表示されます',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/missions'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('ミッションをはじめる'),
            ),
          ],
        ),
      );
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final _RankingEntry entry;

  const _RankingCard({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isProfit = entry.returnPct >= 0;
    final color = isProfit ? AppColors.candleUp : AppColors.candleDown;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 順位
            SizedBox(
              width: 40,
              child: Text(
                medal,
                style: rank <= 3
                    ? const TextStyle(fontSize: 28)
                    : Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // 情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _missionLabel(entry.missionId),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '${_eraLabel(entry.eraId)} ・ ${entry.symbols.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    _formatDate(entry.completedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // リターン
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isProfit ? '+' : ''}${entry.returnPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '¥${_fmt(entry.finalCash)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _missionLabel(String id) {
    const labels = {
      'stage1': 'Stage1: 1社投資',
      'stage2': 'Stage2: 分散投資',
      'stage3': 'Stage3: 積立 vs 一括',
    };
    return labels[id] ?? id;
  }

  String _eraLabel(String id) {
    const labels = {
      'lehman': 'リーマン前後',
      'abenomics': 'アベノミクス',
      'covid': 'コロナ禍',
    };
    return labels[id] ?? id;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';

  String _fmt(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}千万';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return v.toStringAsFixed(0);
  }
}
