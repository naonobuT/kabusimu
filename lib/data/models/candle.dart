class Candle {
  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double close;
  final int? volume;

  const Candle({
    required this.date,
    this.open,
    this.high,
    this.low,
    required this.close,
    this.volume,
  });

  bool get isUp => (open ?? close) <= close;

  factory Candle.fromMap(Map<String, dynamic> map) => Candle(
        date: map['date'] as String,
        open: (map['open'] as num?)?.toDouble(),
        high: (map['high'] as num?)?.toDouble(),
        low: (map['low'] as num?)?.toDouble(),
        close: (map['close'] as num).toDouble(),
        volume: map['volume'] as int?,
      );
}
