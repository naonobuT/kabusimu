import '../data/models/news_event.dart';

class NewsMatcherService {
  final List<NewsEvent> _events;

  NewsMatcherService(this._events) {
    // 日付順にソート（バイナリサーチ用）
    _events.sort((a, b) => a.date.compareTo(b.date));
  }

  NewsEvent? findForDate(String date, String symbol, String category) {
    // バイナリサーチで日付の最初のインデックスを取得
    final idx = _binarySearchFirst(date);
    if (idx < 0) return null;

    // 同じ日付のイベントを順に試し、銘柄にマッチするものを返す
    for (int i = idx; i < _events.length && _events[i].date == date; i++) {
      if (_events[i].affectsCompany(symbol, category)) return _events[i];
    }
    return null;
  }

  // 指定日付の最初のインデックスを返す（存在しなければ -1）
  int _binarySearchFirst(String date) {
    int lo = 0, hi = _events.length - 1, result = -1;
    while (lo <= hi) {
      final mid = (lo + hi) ~/ 2;
      final cmp = _events[mid].date.compareTo(date);
      if (cmp == 0) {
        result = mid;
        hi = mid - 1; // 左側にも同日付がないか探す
      } else if (cmp < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return result;
  }
}
