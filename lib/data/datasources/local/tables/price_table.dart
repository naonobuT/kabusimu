import 'package:drift/drift.dart';

// バンドルされた読み取り専用DBのテーブル定義
class PriceTable extends Table {
  TextColumn get symbol => text()();
  TextColumn get date => text()();
  RealColumn get open => real().nullable()();
  RealColumn get high => real().nullable()();
  RealColumn get low => real().nullable()();
  RealColumn get close => real()();
  IntColumn get volume => integer().nullable()();

  @override
  Set<Column> get primaryKey => {symbol, date};
}
