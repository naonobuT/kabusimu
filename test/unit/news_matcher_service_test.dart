import 'package:flutter_test/flutter_test.dart';
import 'package:stock_simulator_kids/services/news_matcher_service.dart';
import 'package:stock_simulator_kids/data/models/news_event.dart';

NewsEvent _makeEvent({
  required String id,
  required String date,
  List<String> categories = const [],
  List<String> symbols = const [],
  String impact = 'neutral',
}) =>
    NewsEvent(
      id: id,
      date: date,
      titleJa: 'テストイベント $id',
      bodyJa: '本文',
      impact: impact,
      affectedCategories: categories,
      affectedSymbols: symbols,
      emoji: '📰',
    );

void main() {
  group('NewsMatcherService', () {
    test('完全一致する日付のイベントを返す', () {
      final events = [
        _makeEvent(id: 'e1', date: '2020-03-13', categories: ['all']),
      ];
      final svc = NewsMatcherService(events);
      final result = svc.findForDate('2020-03-13', '7974', 'ゲーム・エンタメ');
      expect(result, isNotNull);
      expect(result!.id, 'e1');
    });

    test('存在しない日付は null を返す', () {
      final events = [
        _makeEvent(id: 'e1', date: '2020-03-13', categories: ['all']),
      ];
      final svc = NewsMatcherService(events);
      expect(svc.findForDate('2020-03-14', '7974', 'ゲーム・エンタメ'), isNull);
    });

    test('affectedCategories が all のときすべての銘柄に適用される', () {
      final events = [
        _makeEvent(id: 'all', date: '2020-01-01', categories: ['all']),
      ];
      final svc = NewsMatcherService(events);
      expect(svc.findForDate('2020-01-01', '9999', '未知カテゴリ'), isNotNull);
    });

    test('特定カテゴリに限定されたイベントは他カテゴリに適用されない', () {
      final events = [
        _makeEvent(id: 'game', date: '2020-06-01', categories: ['ゲーム・エンタメ']),
      ];
      final svc = NewsMatcherService(events);
      expect(
          svc.findForDate('2020-06-01', '7203', 'のりもの'), isNull);
      expect(
          svc.findForDate('2020-06-01', '7974', 'ゲーム・エンタメ'), isNotNull);
    });

    test('特定銘柄シンボルに限定されたイベントは他銘柄に適用されない', () {
      final events = [
        _makeEvent(id: 'sym', date: '2020-09-01', symbols: ['7974']),
      ];
      final svc = NewsMatcherService(events);
      expect(svc.findForDate('2020-09-01', '7974', ''), isNotNull);
      expect(svc.findForDate('2020-09-01', '6758', ''), isNull);
    });

    test('イベントリストは日付順にソートされる', () {
      final events = [
        _makeEvent(id: 'late', date: '2021-12-31', categories: ['all']),
        _makeEvent(id: 'early', date: '2019-01-01', categories: ['all']),
      ];
      final svc = NewsMatcherService(events);
      expect(svc.findForDate('2019-01-01', 'X', ''), isNotNull);
      expect(svc.findForDate('2021-12-31', 'X', ''), isNotNull);
    });

    test('空のイベントリストは常に null を返す', () {
      final svc = NewsMatcherService([]);
      expect(svc.findForDate('2020-01-01', 'X', ''), isNull);
    });

    test('同じ日付に複数イベントがある場合、銘柄にマッチするものを返す', () {
      final events = [
        _makeEvent(id: 'sample', date: '2016-06-24', symbols: ['0001']),
        _makeEvent(id: 'brexit', date: '2016-06-24', categories: ['all']),
      ];
      final svc = NewsMatcherService(events);
      // サンプル銘柄は sample イベントにマッチ
      expect(svc.findForDate('2016-06-24', '0001', 'サンプル')?.id, anyOf('sample', 'brexit'));
      // 他銘柄は all カテゴリの brexit にマッチ
      final result = svc.findForDate('2016-06-24', '7974', 'ゲーム・エンタメ');
      expect(result, isNotNull);
      expect(result!.id, 'brexit');
    });
  });
}
