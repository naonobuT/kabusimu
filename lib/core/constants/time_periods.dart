class TimePeriod {
  final String id;
  final String nameJa;
  final String descriptionJa;
  final String startDate;
  final String endDate;
  final String emoji;

  const TimePeriod({
    required this.id,
    required this.nameJa,
    required this.descriptionJa,
    required this.startDate,
    required this.endDate,
    required this.emoji,
  });
}

class TimePeriods {
  TimePeriods._();

  static const List<TimePeriod> all = [
    TimePeriod(
      id: 'lehman',
      nameJa: 'リーマンショック前後',
      descriptionJa: '2005〜2010年。世界的な金融危機が起きた時代。暴落の恐怖と回復を体験しよう。',
      startDate: '2005-01-01',
      endDate: '2010-12-31',
      emoji: '💥',
    ),
    TimePeriod(
      id: 'abenomics',
      nameJa: 'アベノミクス',
      descriptionJa: '2012〜2016年。大規模な金融緩和で株価が大きく上昇した時代。',
      startDate: '2012-01-01',
      endDate: '2016-12-31',
      emoji: '📈',
    ),
    TimePeriod(
      id: 'covid',
      nameJa: 'コロナ禍',
      descriptionJa: '2018〜2023年。感染症による急落と、その後の驚異的な回復を体験しよう。',
      startDate: '2018-01-01',
      endDate: '2023-12-31',
      emoji: '😷',
    ),
  ];

  static TimePeriod? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
