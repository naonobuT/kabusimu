import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  SimulationSessionTable,
  PortfolioPositionTable,
  ProgressTable,
  ImportedSymbolTable,
  TradeLogTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // --- セッション ---
  Future<int> createSession(SimulationSessionTableCompanion entry) =>
      into(simulationSessionTable).insert(entry);

  Future<SimulationSessionTableData?> getSession(int id) =>
      (select(simulationSessionTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> updateSession(SimulationSessionTableCompanion entry) =>
      update(simulationSessionTable).replace(entry);

  Future<void> markSessionCompleted(int sessionId, {double? finalTotalAsset}) =>
      (update(simulationSessionTable)..where((t) => t.id.equals(sessionId)))
          .write(SimulationSessionTableCompanion(
            status: const Value('completed'),
            currentCash: finalTotalAsset != null
                ? Value(finalTotalAsset)
                : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ));

  // --- ポジション ---
  Future<List<PortfolioPositionTableData>> getPositions(int sessionId) =>
      (select(portfolioPositionTable)
            ..where((t) => t.sessionId.equals(sessionId)))
          .get();

  Future<int> upsertPosition(PortfolioPositionTableCompanion entry) =>
      into(portfolioPositionTable)
          .insertOnConflictUpdate(entry);

  Future<int> deletePosition(int positionId) =>
      (delete(portfolioPositionTable)
            ..where((t) => t.id.equals(positionId)))
          .go();

  // --- 進捗 ---
  Future<ProgressTableData?> getProgress(String missionId) =>
      (select(progressTable)..where((t) => t.missionId.equals(missionId)))
          .getSingleOrNull();

  Future<void> upsertProgress(ProgressTableCompanion entry) =>
      into(progressTable).insertOnConflictUpdate(entry);

  Future<List<ProgressTableData>> getAllProgress() =>
      select(progressTable).get();

  // --- インポート済み銘柄 ---
  Future<List<ImportedSymbolTableData>> getImportedSymbols() =>
      select(importedSymbolTable).get();

  Future<void> upsertImportedSymbol(ImportedSymbolTableCompanion entry) =>
      into(importedSymbolTable).insertOnConflictUpdate(entry);

  // --- 取引ログ ---
  Future<int> insertTradeLog(TradeLogTableCompanion entry) =>
      into(tradeLogTable).insert(entry);

  Future<List<TradeLogTableData>> getTradeLog(int sessionId) =>
      (select(tradeLogTable)..where((t) => t.sessionId.equals(sessionId)))
          .get();

  // --- 過去の完了セッション（ランキング用）---
  Future<List<SimulationSessionTableData>> getCompletedSessions() =>
      (select(simulationSessionTable)
            ..where((t) => t.status.equals('completed'))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  // --- 起動時クリーンアップ：途中で放棄されたセッションを破棄 ---
  Future<void> abandonActiveSessions() =>
      (update(simulationSessionTable)..where((t) => t.status.equals('active')))
          .write(SimulationSessionTableCompanion(
            status: const Value('abandoned'),
            updatedAt: Value(DateTime.now()),
          ));
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dbDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbDir.path, 'app.db'));
      return NativeDatabase(file);
    });
