class NewsEvent {
  final String id;
  final String date;
  final String titleJa;
  final String bodyJa;
  final String impact; // 'positive' | 'negative' | 'neutral'
  final List<String> affectedCategories;
  final List<String> affectedSymbols;
  final String emoji;

  const NewsEvent({
    required this.id,
    required this.date,
    required this.titleJa,
    required this.bodyJa,
    required this.impact,
    this.affectedCategories = const [],
    this.affectedSymbols = const [],
    required this.emoji,
  });

  bool get isPositive => impact == 'positive';
  bool get isNegative => impact == 'negative';

  bool affectsCompany(String symbol, String category) {
    if (affectedCategories.contains('all')) return true;
    if (affectedSymbols.contains(symbol)) return true;
    if (affectedCategories.contains(category)) return true;
    return false;
  }

  factory NewsEvent.fromJson(Map<String, dynamic> json) => NewsEvent(
        id: json['id'] as String,
        date: json['date'] as String,
        titleJa: json['titleJa'] as String,
        bodyJa: json['bodyJa'] as String,
        impact: json['impact'] as String,
        affectedCategories: (json['affectedCategories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        affectedSymbols: (json['affectedSymbols'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        emoji: json['emoji'] as String,
      );
}
