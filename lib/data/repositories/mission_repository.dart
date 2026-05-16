import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import '../models/mission.dart';
import '../datasources/local/app_database.dart';

class MissionRepository {
  final AppDatabase _db;
  List<Mission>? _cached;

  MissionRepository(this._db);

  Future<List<Mission>> getAll() async {
    if (_cached != null) return _cached!;
    try {
      final json = await rootBundle.loadString('assets/data/missions.json');
      final decoded = jsonDecode(json);
      if (decoded is! List) throw FormatException('missions.json: List expected');
      _cached = decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => Mission.fromJson(e))
          .toList();
    } catch (e) {
      _cached = [];
    }
    return _cached!;
  }

  Future<Mission?> findById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<MissionProgress>> getAllProgress() async {
    final rows = await _db.getAllProgress();
    return rows.map((r) {
      List<String> badges = [];
      try {
        final decoded = jsonDecode(r.badgesJson);
        if (decoded is List) badges = decoded.whereType<String>().toList();
      } catch (_) {}
      return MissionProgress(
        missionId: r.missionId,
        isCompleted: r.status == 'completed',
        earnedBadgeIds: badges,
        completedAt: r.completedAt,
      );
    }).toList();
  }

  Future<bool> isUnlocked(String missionId) async {
    if (missionId == 'stage1') return true; // Stage1は常にアンロック
    final mission = await findById(missionId);
    if (mission == null) return false;
    // 前のステージが完了していればアンロック
    final prevStageId = 'stage${mission.stage - 1}';
    final progress = await _db.getProgress(prevStageId);
    return progress?.status == 'completed';
  }

  Future<void> markCompleted(
    String missionId,
    List<String> badgeIds,
  ) async {
    await _db.upsertProgress(ProgressTableCompanion.insert(
      missionId: missionId,
      status: 'completed',
      badgesJson: jsonEncode(badgeIds),
      completedAt: drift.Value(DateTime.now()),
    ));
  }
}
