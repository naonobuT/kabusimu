import 'package:flutter_test/flutter_test.dart';
import 'package:stock_simulator_kids/services/jquants_csv_parser.dart';

const _header =
    'Date,Code,Open,High,Low,Close,Volume,TurnoverValue,AdjustmentFactor,'
    'AdjustmentOpen,AdjustmentHigh,AdjustmentLow,AdjustmentClose,AdjustmentVolume\n';

String _makeRow(String date, String code, double close,
    {double adjustClose = 0}) {
  final ac = adjustClose == 0 ? close : adjustClose;
  return '$date,$code,${close - 10},${close + 10},${close - 20},$close,'
      '100000,999999,1.0,${ac - 10},${ac + 10},${ac - 20},$ac,100000\n';
}

String _makeCsv(String code, {int rows = 70, double basePrice = 1000.0}) {
  final sb = StringBuffer(_header);
  var dayCount = 0;
  for (int month = 1; month <= 12 && dayCount < rows; month++) {
    for (int day = 1; day <= 28 && dayCount < rows; day++) {
      final date =
          '2020-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      sb.write(_makeRow(date, code, basePrice + dayCount));
      dayCount++;
    }
  }
  return sb.toString();
}

void main() {
  final parser = JQuantsCsvParser();

  group('JQuantsCsvParser', () {
    test('J-Quants 形式を正常にパースする', () {
      final csv = _makeCsv('79740');
      final result = parser.parse(csv);
      expect(result.isSuccess, isTrue);
      expect(result.candles.length, 70);
      expect(result.symbol, '7974'); // 末尾の0を除去
    });

    test('AdjustmentClose を優先して使用する', () {
      final sb = StringBuffer(_header);
      sb.write(_makeRow('2020-01-01', '79740', 1000, adjustClose: 950));
      for (int i = 1; i < 69; i++) {
        final date =
            '2020-02-${i.toString().padLeft(2, '0')}';
        sb.write(_makeRow(date, '79740', 1000.0 + i));
      }
      final result = parser.parse(sb.toString());
      expect(result.isSuccess, isTrue);
      expect(result.candles.first.close, closeTo(950, 0.01));
    });

    test('60行未満はバリデーションエラー', () {
      final csv = _makeCsv('79740', rows: 30);
      final result = parser.parse(csv);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('少なすぎます'));
    });

    test('ヘッダー不一致はエラー', () {
      const csv = 'wrong,header\n2020-01-01,7974,1000\n';
      final result = parser.parse(csv);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains('形式が違います'));
    });

    test('5桁末尾0の銘柄コードを正規化する', () {
      final csv = _makeCsv('72030'); // 7203 + 0
      final result = parser.parse(csv);
      expect(result.symbol, '7203');
    });

    test('4桁コードはそのまま保持', () {
      final csv = _makeCsv('7203');
      final result = parser.parse(csv);
      expect(result.symbol, '7203');
    });

    test('日付の範囲を正しく取得する', () {
      final csv = _makeCsv('79740', rows: 70);
      final result = parser.parse(csv);
      expect(result.firstDate, isNotEmpty);
      expect(result.lastDate, isNotEmpty);
      expect(result.lastDate.compareTo(result.firstDate), greaterThan(0));
    });

    test('空ファイルはエラー', () {
      final result = parser.parse('');
      expect(result.isSuccess, isFalse);
    });
  });
}
