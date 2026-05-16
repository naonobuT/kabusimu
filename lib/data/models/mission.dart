class MissionObjective {
  final String type;
  final int points;

  const MissionObjective({required this.type, required this.points});

  factory MissionObjective.fromJson(Map<String, dynamic> json) =>
      MissionObjective(
        type: json['type'] as String,
        points: json['points'] as int,
      );
}

class Mission {
  final String id;
  final int stage;
  final String titleJa;
  final String descriptionJa;
  final String emoji;
  final int maxCompanies;
  final List<String> allowedEraIds;
  final bool dcaEnabled;
  final int? dcaMonthlyAmount;
  final List<MissionObjective> objectives;

  const Mission({
    required this.id,
    required this.stage,
    required this.titleJa,
    required this.descriptionJa,
    required this.emoji,
    required this.maxCompanies,
    required this.allowedEraIds,
    this.dcaEnabled = false,
    this.dcaMonthlyAmount,
    required this.objectives,
  });

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        stage: json['stage'] as int,
        titleJa: json['titleJa'] as String,
        descriptionJa: json['descriptionJa'] as String,
        emoji: json['emoji'] as String,
        maxCompanies: json['maxCompanies'] as int,
        allowedEraIds: (json['allowedEraIds'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        dcaEnabled: json['dcaEnabled'] as bool? ?? false,
        dcaMonthlyAmount: json['dcaMonthlyAmount'] as int?,
        objectives: (json['objectives'] as List<dynamic>)
            .map((e) => MissionObjective.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MissionProgress {
  final String missionId;
  final bool isCompleted;
  final List<String> earnedBadgeIds;
  final DateTime? completedAt;

  const MissionProgress({
    required this.missionId,
    required this.isCompleted,
    this.earnedBadgeIds = const [],
    this.completedAt,
  });
}
