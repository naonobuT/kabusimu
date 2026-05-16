import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BuyDialog extends StatefulWidget {
  final String companyName;
  final double currentPrice;
  final double availableCash;
  final void Function(int shares) onConfirm;

  const BuyDialog({
    super.key,
    required this.companyName,
    required this.currentPrice,
    required this.availableCash,
    required this.onConfirm,
  });

  @override
  State<BuyDialog> createState() => _BuyDialogState();
}

class _BuyDialogState extends State<BuyDialog> {
  int _shares = 1;

  int get _maxShares {
    if (widget.currentPrice <= 0) return 0;
    return (widget.availableCash / widget.currentPrice).floor().clamp(0, 9999);
  }

  double get _totalCost => _shares * widget.currentPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.companyName}を買う'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '現在値: ¥${widget.currentPrice.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _shares > 1
                    ? () => setState(() => _shares--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                '$_shares株',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _shares < _maxShares
                    ? () => setState(() => _shares++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // クイック選択
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [10, 100, _maxShares].map((n) {
              return TextButton(
                // _maxShares == 0 のとき clamp(1, 0) で RangeError になるのを防ぐ
                onPressed: n > 0 && n <= _maxShares
                    ? () => setState(() =>
                        _shares = n.clamp(1, _maxShares))
                    : null,
                child: Text('$n株'),
              );
            }).toList(),
          ),
          const Divider(),
          Text(
            '購入金額: ¥${_totalCost.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '残り現金: ¥${(widget.availableCash - _totalCost).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _shares > 0 && _totalCost <= widget.availableCash
              ? () {
                  widget.onConfirm(_shares);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('買う！'),
        ),
      ],
    );
  }
}
