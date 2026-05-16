/// ミライテック株式会社（銘柄コード: 0001）のサンプル株価データ生成スクリプト
///
/// 実行方法:
///   dart scripts/generate_sample_data.dart
///
/// 出力: assets/data/sample_prices.csv
///
/// 幾何ブラウン運動（GBM）ベースで生成し、以下の教育的シナリオを埋め込む:
///   - 2016-06 : 新製品発表による急騰
///   - 2018-02 : 世界的株価急落
///   - 2019-10 : 緩やかな下落（消費増税）
///   - 2020-03 : コロナ暴落
///   - 2020-07 : 急回復

import 'dart:io';
import 'dart:math';

void main() {
  const seed = 42;
  const startDate = '2015-01-05';
  const endDate = '2020-12-31';
  const startPrice = 2000.0;
  const outputPath = 'assets/data/sample_prices.csv';

  final rng = _SeededRandom(seed);
  final rows = <String>[];
  rows.add('date,open,high,low,close,volume');

  double price = startPrice;
  var date = DateTime.parse(startDate);
  final end = DateTime.parse(endDate);

  while (!date.isAfter(end)) {
    // 土日スキップ
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
      continue;
    }

    final dateStr = _fmt(date);

    // イベントによるドリフト調整
    final drift = _getDrift(dateStr);
    final vol = _getVolatility(dateStr);

    final dailyReturn = drift + rng.nextGaussian() * vol;
    price = (price * exp(dailyReturn)).clamp(100.0, 50000.0);

    final highFactor = 1.0 + rng.nextDouble() * 0.015;
    final lowFactor = 1.0 - rng.nextDouble() * 0.015;
    final openFactor = 1.0 + (rng.nextDouble() - 0.5) * 0.008;

    final high = price * highFactor;
    final low = price * lowFactor;
    final open = price * openFactor;
    final volume = (300000 + rng.nextDouble() * 1200000).toInt();

    rows.add('$dateStr,'
        '${open.toStringAsFixed(1)},'
        '${high.toStringAsFixed(1)},'
        '${low.toStringAsFixed(1)},'
        '${price.toStringAsFixed(1)},'
        '$volume');

    date = date.add(const Duration(days: 1));
  }

  File(outputPath).writeAsStringSync(rows.join('\n'));
  print('✅ 生成完了: $outputPath (${rows.length - 1}行)');
}

/// 日付に応じたドリフト（年率リターンを日次換算）
double _getDrift(String date) {
  // 通常: 年率+5% ≒ 日次+0.02%
  double annualReturn = 0.05;

  // 新製品発表ブーム（2016-06 〜 2016-09）
  if (date.compareTo('2016-06-01') >= 0 && date.compareTo('2016-09-30') <= 0) {
    annualReturn = 0.80;
  }
  // 世界株安（2018-02）
  else if (date.compareTo('2018-02-01') >= 0 && date.compareTo('2018-02-28') <= 0) {
    annualReturn = -2.0;
  }
  // 消費増税後の低迷（2019-10 〜 2020-01）
  else if (date.compareTo('2019-10-01') >= 0 && date.compareTo('2020-01-31') <= 0) {
    annualReturn = -0.20;
  }
  // コロナ暴落（2020-02 〜 2020-03）
  else if (date.compareTo('2020-02-20') >= 0 && date.compareTo('2020-03-31') <= 0) {
    annualReturn = -3.0;
  }
  // コロナ回復（2020-04 〜 2020-12）
  else if (date.compareTo('2020-04-01') >= 0 && date.compareTo('2020-12-31') <= 0) {
    annualReturn = 1.5;
  }

  return annualReturn / 252; // 年次→日次
}

/// 日付に応じたボラティリティ
double _getVolatility(String date) {
  // 暴落期はボラ高め
  if (date.compareTo('2018-02-01') >= 0 && date.compareTo('2018-03-31') <= 0) {
    return 0.04;
  }
  if (date.compareTo('2020-02-20') >= 0 && date.compareTo('2020-04-30') <= 0) {
    return 0.05;
  }
  return 0.015; // 通常: 日次1.5%
}

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _SeededRandom {
  int _state;
  _SeededRandom(this._state);

  double nextDouble() {
    _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _state / 0xFFFFFFFF;
  }

  // ボックス・ミュラー法で正規分布乱数
  double nextGaussian() {
    final u1 = nextDouble();
    final u2 = nextDouble();
    return sqrt(-2 * log(u1 + 1e-10)) * cos(2 * pi * u2);
  }
}
