import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/candle.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<Candle> candles;
  final int visibleCount; // 画面に表示するローソク足の本数

  const CandlestickChartWidget({
    super.key,
    required this.candles,
    this.visibleCount = 60,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  Candle? _tappedCandle;
  final _chartKey = GlobalKey();

  List<Candle> get _visibleCandles {
    final end = widget.candles.length;
    final start = (end - widget.visibleCount).clamp(0, end);
    return widget.candles.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const Center(
        child: Text('データを読み込み中...', style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details),
            child: CustomPaint(
              key: _chartKey,
              painter: _CandlestickPainter(candles: _visibleCandles),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // 出来高バー
        SizedBox(
          height: 48,
          child: CustomPaint(
            painter: _VolumePainter(candles: _visibleCandles),
            child: const SizedBox.expand(),
          ),
        ),
        // タップ時ツールチップ
        if (_tappedCandle != null)
          _CandleTooltip(candle: _tappedCandle!),
      ],
    );
  }

  void _handleTap(TapUpDetails details) {
    final candles = _visibleCandles;
    if (candles.isEmpty) return;

    final box = _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final chartWidth = box.size.width;

    final candleWidth = chartWidth / candles.length;
    final idx = (details.localPosition.dx / candleWidth).floor();

    if (idx >= 0 && idx < candles.length) {
      setState(() => _tappedCandle = candles[idx]);
    } else {
      setState(() => _tappedCandle = null);
    }
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Candle> candles;

  _CandlestickPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final prices = candles
        .expand((c) => [
              c.high ?? c.close,
              c.low ?? c.close,
            ])
        .toList();
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    final candleWidth = size.width / candles.length;
    final bodyWidth = (candleWidth * 0.6).clamp(2.0, 20.0);

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = candleWidth * i + candleWidth / 2;

      double toY(double price) =>
          size.height - ((price - minPrice) / priceRange) * size.height;

      final isUp = c.isUp;
      final color = isUp ? AppColors.candleUp : AppColors.candleDown;
      final paint = Paint()..color = color;

      final closeY = toY(c.close);
      final openY = toY(c.open ?? c.close);
      final highY = toY(c.high ?? c.close);
      final lowY = toY(c.low ?? c.close);

      // ヒゲ
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        Paint()
          ..color = AppColors.candleWick
          ..strokeWidth = 1.0,
      );

      // ボディ
      final bodyTop = isUp ? closeY : openY;
      final bodyBottom = isUp ? openY : closeY;
      final bodyHeight = (bodyBottom - bodyTop).abs().clamp(1.0, double.infinity);

      canvas.drawRect(
        Rect.fromLTWH(x - bodyWidth / 2, bodyTop, bodyWidth, bodyHeight),
        paint,
      );
    }

    // 移動平均線 MA5
    _drawMA(canvas, size, candles, 5, Colors.yellow.withValues(alpha: 0.8),
        maxPrice, minPrice, priceRange, candleWidth);
    // MA25
    _drawMA(canvas, size, candles, 25, Colors.cyan.withValues(alpha: 0.8),
        maxPrice, minPrice, priceRange, candleWidth);
  }

  void _drawMA(
    Canvas canvas,
    Size size,
    List<Candle> candles,
    int period,
    Color color,
    double maxPrice,
    double minPrice,
    double priceRange,
    double candleWidth,
  ) {
    if (candles.length < period) return;

    double toY(double price) =>
        size.height - ((price - minPrice) / priceRange) * size.height;

    final path = Path();
    bool started = false;

    for (int i = period - 1; i < candles.length; i++) {
      final avg = candles
              .sublist(i - period + 1, i + 1)
              .map((c) => c.close)
              .reduce((a, b) => a + b) /
          period;
      final x = candleWidth * i + candleWidth / 2;
      final y = toY(avg);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CandlestickPainter old) => old.candles != candles;
}

class _VolumePainter extends CustomPainter {
  final List<Candle> candles;

  _VolumePainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final volumes = candles.map((c) => c.volume ?? 0).toList();
    final maxVol = volumes.fold(0, (a, b) => a > b ? a : b);
    if (maxVol == 0) return;

    final candleWidth = size.width / candles.length;
    final barWidth = (candleWidth * 0.6).clamp(2.0, 20.0);

    for (int i = 0; i < candles.length; i++) {
      final vol = candles[i].volume ?? 0;
      final barHeight = (vol / maxVol) * size.height;
      final x = candleWidth * i + candleWidth / 2;

      canvas.drawRect(
        Rect.fromLTWH(
          x - barWidth / 2,
          size.height - barHeight,
          barWidth,
          barHeight,
        ),
        Paint()
          ..color = (candles[i].isUp ? AppColors.candleUp : AppColors.candleDown)
              .withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_VolumePainter old) => old.candles != candles;
}

class _CandleTooltip extends StatelessWidget {
  final Candle candle;

  const _CandleTooltip({required this.candle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('日付', candle.date),
          _item('始値', '¥${candle.open?.toStringAsFixed(0) ?? '-'}'),
          _item('高値', '¥${candle.high?.toStringAsFixed(0) ?? '-'}'),
          _item('安値', '¥${candle.low?.toStringAsFixed(0) ?? '-'}'),
          _item('終値', '¥${candle.close.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _item(String label, String value) => Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
