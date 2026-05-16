import 'package:drift/drift.dart';

class SimulationSessionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get missionId => text()();
  TextColumn get eraId => text()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();
  TextColumn get selectedSymbolsJson => text()(); // JSON配列
  RealColumn get initialCash => real()();
  RealColumn get currentCash => real()();
  TextColumn get status => text()(); // 'active' | 'completed'
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class PortfolioPositionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(SimulationSessionTable, #id)();
  TextColumn get symbol => text()();
  IntColumn get shares => integer()();
  RealColumn get avgPrice => real()();
}

class ProgressTable extends Table {
  TextColumn get missionId => text()();
  TextColumn get status => text()(); // 'locked' | 'unlocked' | 'completed'
  TextColumn get badgesJson => text()(); // JSON配列
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {missionId};
}

class ImportedSymbolTable extends Table {
  TextColumn get symbol => text()();
  TextColumn get nameJa => text().nullable()();
  TextColumn get firstDate => text()();
  TextColumn get lastDate => text()();
  IntColumn get rowCount => integer()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {symbol};
}

class TradeLogTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(SimulationSessionTable, #id)();
  TextColumn get symbol => text()();
  TextColumn get tradeDate => text()(); // シミュレーション内の日付
  TextColumn get side => text()(); // 'buy' | 'sell'
  IntColumn get shares => integer()();
  RealColumn get price => real()();
  DateTimeColumn get executedAt => dateTime()();
}
