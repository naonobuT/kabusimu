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
    final json = await rootBundle.loadString('assets/data/missions.json');
    final list = jsonDecode(json) as List<dynamic>;
    _cached = list.map((e) => Mission.fromJson(e as Map<String, dynamic>)).toList();
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
      final badges = (jsonDecode(r.badgesJson) as List<dynamic>)
          .map((e) => e as String)
          .toList();
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
