import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/app_providers.dart';

class MissionSelectScreen extends ConsumerWidget {
  const MissionSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage2Async = ref.watch(missionUnlockedProvider('stage2'));
    final stage3Async = ref.watch(missionUnlockedProvider('stage3'));

    return Scaffold(
      appBar: AppBar(title: const Text('ミッション選択')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'どのミッションにチャレンジする？',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _MissionCard(
            stage: 1,
            emoji: '🌱',
            title: '1社に投資しよう',
            description: 'お気に入りの1社を選んで投資してみよう。株価の基本をマスター！',
            color: Colors.green,
            isUnlocked: true,
            onTap: () => context.push('/missions/stage1/eras'),
          ),
          const SizedBox(height: 16),
          stage2Async.when(
            loading: () => const _MissionCardSkeleton(stage: 2),
            error: (_, __) => const _MissionCardSkeleton(stage: 2),
            data: (unlocked) => _MissionCard(
              stage: 2,
              emoji: '⚖️',
              title: '分散投資にチャレンジ',
              description: '複数の会社に分けて投資しよう。リスクを分散させる方法を学ぼう！',
              color: AppColors.primary,
              isUnlocked: unlocked,
              onTap: () => context.push('/missions/stage2/eras'),
            ),
          ),
          const SizedBox(height: 16),
          stage3Async.when(
            loading: () => const _MissionCardSkeleton(stage: 3),
            error: (_, __) => const _MissionCardSkeleton(stage: 3),
            data: (unlocked) => _MissionCard(
              stage: 3,
              emoji: '📅',
              title: '積立投資 vs 一括投資',
              description: '毎月コツコツ買う方法と、一度にまとめて買う方法、どっちが勝つ？',
              color: Colors.orange,
              isUnlocked: unlocked,
              onTap: () => context.push('/missions/stage3/eras'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCardSkeleton extends StatelessWidget {
  final int stage;
  const _MissionCardSkeleton({required this.stage});

  @override
  Widget build(BuildContext context) => const Card(
        child: SizedBox(height: 88),
      );
}

class _MissionCard extends StatelessWidget {
  final int stage;
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _MissionCard({
    required this.stage,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        child: InkWell(
          onTap: isUnlocked ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stage $stage: $title',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked ? Icons.chevron_right : Icons.lock,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
