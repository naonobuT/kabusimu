import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/local/price_database.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/repositories/mission_repository.dart';
import '../../data/repositories/price_repository.dart';
import '../../data/models/company.dart';
import '../../data/models/mission.dart';

// --- DB ---
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final priceDatabaseProvider = Provider<PriceDatabase>((ref) {
  final db = PriceDatabase();
  ref.onDispose(db.close);
  return db;
});

// --- リポジトリ ---
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(appDatabaseProvider));
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(ref.watch(appDatabaseProvider));
});

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(ref.watch(priceDatabaseProvider));
});

// --- データ ---
final companiesProvider = FutureProvider<List<Company>>((ref) async {
  return ref.watch(companyRepositoryProvider).getAll();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(companyRepositoryProvider).getCategories();
});

final missionsProvider = FutureProvider<List<Mission>>((ref) async {
  return ref.watch(missionRepositoryProvider).getAll();
});

final missionProgressProvider = FutureProvider<List<MissionProgress>>((ref) async {
  return ref.watch(missionRepositoryProvider).getAllProgress();
});

// ミッションがアンロック済みか
final missionUnlockedProvider =
    FutureProvider.family<bool, String>((ref, missionId) async {
  return ref.watch(missionRepositoryProvider).isUnlocked(missionId);
});

// セッションの取引ログ（バッジ判定用）
final tradeLogsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, sessionId) async {
  final logs = await ref.watch(appDatabaseProvider).getTradeLog(sessionId);
  return logs
      .asMap()
      .entries
      .map((e) => {
            'index': e.key,
            'side': e.value.side,
            'symbol': e.value.symbol,
            'shares': e.value.shares,
            'price': e.value.price,
          })
      .toList();
});
