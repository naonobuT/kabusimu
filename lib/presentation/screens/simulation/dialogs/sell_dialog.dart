import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SellDialog extends StatefulWidget {
  final String companyName;
  final double currentPrice;
  final int sharesHeld;
  final void Function(int shares) onConfirm;

  const SellDialog({
    super.key,
    required this.companyName,
    required this.currentPrice,
    required this.sharesHeld,
    required this.onConfirm,
  });

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  int _shares = 1;

  double get _proceeds => _shares * widget.currentPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.companyName}を売る'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '現在値: ¥${widget.currentPrice.toStringAsFixed(0)}　'
            '保有: ${widget.sharesHeld}株',
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
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.candleDown),
              ),
              const SizedBox(width: 16),
              Text(
                '$_shares株',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _shares < widget.sharesHeld
                    ? () => setState(() => _shares++)
                    : null,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.candleDown),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(
                    () => _shares = (widget.sharesHeld ~/ 2).clamp(1, widget.sharesHeld)),
                child: const Text('半分'),
              ),
              TextButton(
                onPressed: () => setState(() => _shares = widget.sharesHeld),
                child: const Text('全部'),
              ),
            ],
          ),
          const Divider(),
          Text(
            '売却金額: ¥${_proceeds.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.candleDown,
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
          onPressed: _shares > 0
              ? () {
                  widget.onConfirm(_shares);
                  Navigator.pop(context);
                }
              : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.candleDown),
          child: const Text('売る！'),
        ),
      ],
    );
  }
}
