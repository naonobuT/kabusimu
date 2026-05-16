import '../data/models/news_event.dart';

class NewsMatcherService {
  final List<NewsEvent> _events;

  NewsMatcherService(this._events) {
    // 日付順にソート（バイナリサーチ用）
    _events.sort((a, b) => a.date.compareTo(b.date));
  }

  NewsEvent? findForDate(String date, String symbol, String category) {
    // 完全一致検索（ローソク足1本 = 1日単位）
    final idx = _binarySearch(date);
    if (idx < 0) return null;

    final event = _events[idx];
    if (!event.affectsCompany(symbol, category)) return null;
    return event;
  }

  int _binarySearch(String date) {
    int lo = 0, hi = _events.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final cmp = _events[mid].date.compareTo(date);
      if (cmp == 0) return mid;
      if (cmp < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return -1;
  }
}
