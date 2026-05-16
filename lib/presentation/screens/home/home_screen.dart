import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('カブシミュ', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                '株式投資シミュレーター',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 40),
              // サンプルバナー
              _SampleBanner(),
              const SizedBox(height: 32),
              // メインボタン
              _MenuButton(
                icon: Icons.play_arrow_rounded,
                label: 'ミッションをはじめる',
                color: AppColors.primary,
                onTap: () => context.push('/missions'),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.leaderboard,
                label: 'ランキング',
                color: AppColors.accent,
                onTap: () => context.push('/ranking'),
              ),
              const SizedBox(height: 16),
              _MenuButton(
                icon: Icons.upload_file,
                label: 'データを読み込む（J-Quants）',
                color: Colors.green,
                onTap: () => context.push('/import'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SampleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🎮', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'まずはサンプルで試してみよう！',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '架空の会社「ミライテック」でいますぐ練習できるよ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
