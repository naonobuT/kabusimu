import 'package:flutter/services.dart';
import '../datasources/local/price_database.dart';
import '../models/candle.dart';

class PriceRepository {
  final PriceDatabase _db;

  PriceRepository(this._db);

  Future<List<Candle>> getCandles(
    String symbol,
    String fromDate,
    String toDate,
  ) async {
    // サンプル銘柄はDBではなくCSVアセットから読み込む
    if (symbol == '0001') return _getSampleCandles(fromDate, toDate);

    final rows = await _db.getCandles(symbol, fromDate, toDate);
    return rows.map((r) => Candle(
      date: r.date,
      open: r.open,
      high: r.high,
      low: r.low,
      close: r.close,
      volume: r.volume,
    )).toList();
  }

  Future<List<Candle>> _getSampleCandles(String fromDate, String toDate) async {
    try {
      final csv = await rootBundle.loadString('assets/data/sample_prices.csv');
      final lines = csv.split('\n');
      final candles = <Candle>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final cols = line.split(',');
        if (cols.length < 6) continue;
        final date = cols[0].trim();
        if (date.compareTo(fromDate) < 0) continue;
        if (date.compareTo(toDate) > 0) break;
        candles.add(Candle(
          date: date,
          open: double.tryParse(cols[1]),
          high: double.tryParse(cols[2]),
          low: double.tryParse(cols[3]),
          close: double.tryParse(cols[4]) ?? 0,
          volume: int.tryParse(cols[5].isNotEmpty ? cols[5] : '0'),
        ));
      }
      return candles;
    } catch (_) {
      // CSVが未生成の場合はインメモリ生成にフォールバック
      return _generateInMemory(fromDate, toDate);
    }
  }

  // CSVなしでも動くインメモリフォールバック
  List<Candle> _generateInMemory(String fromDate, String toDate) {
    final candles = <Candle>[];
    double price = 2000.0;
    var date = DateTime.parse('${fromDate.substring(0, 7)}-01');
    final end = DateTime.parse('${toDate.substring(0, 7)}-28');
    var seed = 42;

    double rand() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return seed / 0xFFFFFFFF;
    }

    while (date.isBefore(end)) {
      if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
        final r = 0.0002 + rand() * 0.03 - 0.015;
        price = (price * (1 + r)).clamp(100.0, 100000.0);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
        candles.add(Candle(
          date: dateStr,
          open: price * (1 + rand() * 0.005 - 0.0025),
          high: price * (1 + rand() * 0.01),
          low: price * (1 - rand() * 0.01),
          close: price,
          volume: (500000 + (rand() * 1000000).toInt()),
        ));
      }
      date = date.add(const Duration(days: 1));
    }
    return candles;
  }
}
