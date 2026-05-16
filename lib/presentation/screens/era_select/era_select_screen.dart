import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/time_periods.dart';

class EraSelectScreen extends StatelessWidget {
  final String missionId;

  const EraSelectScreen({super.key, required this.missionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('時代を選ぼう')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'どの時代を旅する？',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '歴史的な出来事と株価の動きを体験しよう',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ...TimePeriods.all.map(
            (era) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _EraCard(
                era: era,
                onTap: () => context.push(
                  '/missions/$missionId/eras/${era.id}/companies',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EraCard extends StatelessWidget {
  final TimePeriod era;
  final VoidCallback onTap;

  const _EraCard({required this.era, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(era.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          era.nameJa,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${era.startDate.substring(0, 4)}年 〜 ${era.endDate.substring(0, 4)}年',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                era.descriptionJa,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
