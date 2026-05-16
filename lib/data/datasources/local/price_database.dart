import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/price_table.dart';

part 'price_database.g.dart';

// バンドルされた株価データ（読み取り専用）
@DriftDatabase(tables: [PriceTable])
class PriceDatabase extends _$PriceDatabase {
  PriceDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<PriceTableData>> getCandles(
    String symbol,
    String fromDate,
    String toDate,
  ) =>
      (select(priceTable)
            ..where((t) =>
                t.symbol.equals(symbol) &
                t.date.isBiggerOrEqualValue(fromDate) &
                t.date.isSmallerOrEqualValue(toDate))
            ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Future<List<String>> getAvailableDates(String symbol) async {
    final rows = await (select(priceTable)
          ..where((t) => t.symbol.equals(symbol))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    return rows.map((r) => r.date).toList();
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbDir.path, 'stock_prices.db'));
      if (!dbFile.existsSync()) {
        try {
          // Try to copy bundled DB (populated via J-Quants import tool)
          final data = await rootBundle.load('assets/data/stock_prices.db');
          await dbFile.writeAsBytes(data.buffer.asUint8List());
        } catch (_) {
          // No bundled DB yet – NativeDatabase will create an empty one
        }
      }
      return NativeDatabase(dbFile);
    });
