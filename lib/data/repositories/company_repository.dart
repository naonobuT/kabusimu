import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/company.dart';
import '../datasources/local/app_database.dart';

class CompanyRepository {
  final AppDatabase _db;
  List<Company>? _cached;

  CompanyRepository(this._db);

  Future<List<Company>> getAll() async {
    if (_cached != null) return _cached!;

    final json = await rootBundle.loadString('assets/data/companies.json');
    final list = jsonDecode(json) as List<dynamic>;
    final bundled = list.map((e) => Company.fromJson(e as Map<String, dynamic>)).toList();

    // インポート済み銘柄をDBから追加
    final imported = await _db.getImportedSymbols();
    final importedCompanies = imported.map((row) => Company(
      symbol: row.symbol,
      nameJa: row.nameJa ?? row.symbol,
      category: 'インポート済み',
      descriptionJa: 'J-Quantsからインポートしたデータです。',
      funFact: '${row.firstDate} 〜 ${row.lastDate}（${row.rowCount}日分）',
      logoAsset: 'assets/images/company_logos/imported.png',
      colorHex: '455A64',
    )).toList();

    _cached = [...bundled, ...importedCompanies];
    return _cached!;
  }

  Future<List<Company>> getByCategory(String category) async {
    final all = await getAll();
    return all.where((c) => c.category == category).toList();
  }

  Future<Company?> findBySymbol(String symbol) async {
    final all = await getAll();
    try {
      return all.firstWhere((c) => c.symbol == symbol);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getCategories() async {
    final all = await getAll();
    return all.map((c) => c.category).toSet().toList();
  }

  void invalidateCache() => _cached = null;
}
