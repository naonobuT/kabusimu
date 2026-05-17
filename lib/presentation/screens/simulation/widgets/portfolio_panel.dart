import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/portfolio_position.dart';
import '../../../../data/models/simulation_session.dart';

class PortfolioPanel extends StatelessWidget {
  final SimulationState state;

  const PortfolioPanel({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final returnPct = state.totalReturnPct;
    final isProfit = returnPct >= 0;

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 総資産サマリー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ValueItem(
                label: '総資産',
                value: '¥${_formatNumber(state.totalAssetValue)}',
                valueStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isProfit
                      ? AppColors.candleUp.withValues(alpha: 0.2)
                      : AppColors.candleDown.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isProfit ? '+' : ''}${returnPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isProfit ? AppColors.candleUp : AppColors.candleDown,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ValueItem(
                label: '現金',
                value: '¥${_formatNumber(state.session.currentCash)}',
              ),
              const SizedBox(width: 24),
              _ValueItem(
                label: '株式評価額',
                value: '¥${_formatNumber(state.totalStockValue)}',
              ),
            ],
          ),
          // ポジション一覧
          if (state.positions.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 16),
            ...state.positions.values.map((p) => _PositionRow(position: p)),
          ],
        ],
      ),
    );
  }

  String _formatNumber(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}千万';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return v.toStringAsFixed(0);
  }
}

class _ValueItem extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _ValueItem({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PositionRow extends StatelessWidget {
  final PortfolioPosition position;

  const _PositionRow({required this.position});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              position.companyNameJa,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            '${position.shares}株',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Text(
            '${position.isProfit ? '+' : ''}${position.unrealizedPnlPct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: position.isProfit ? AppColors.candleUp : AppColors.candleDown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
