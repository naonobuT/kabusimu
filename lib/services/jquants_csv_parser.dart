import '../data/models/candle.dart';

class JQuantsParseResult {
  final String symbol;
  final List<Candle> candles;
  final String firstDate;
  final String lastDate;
  final String? error;

  const JQuantsParseResult({
    required this.symbol,
    required this.candles,
    required this.firstDate,
    required this.lastDate,
    this.error,
  });

  bool get isSuccess => error == null && candles.isNotEmpty;
}

class JQuantsCsvParser {
  // J-Quants /v1/prices/daily_quotes 形式のヘッダー定義
  static const _requiredColumns = ['Date', 'Code', 'Close'];
  static const _minRows = 60;

  JQuantsParseResult parse(String csvContent) {
    final lines = csvContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    if (lines.isEmpty) {
      return _error('ファイルが空です');
    }

    // ヘッダー解析
    final header = lines[0].split(',').map((h) => h.trim().replaceAll('"', '')).toList();
    final colIndex = _buildColumnIndex(header);

    if (colIndex == null) {
      return _error(
        'ファイルの形式が違います。\nJ-QuantsからダウンロードしたCSVを使ってください。\n'
        '必要なカラム: ${_requiredColumns.join(", ")}',
      );
    }

    final candles = <Candle>[];
    String? symbol;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _splitCsvLine(line);
      if (cols.length <= colIndex['Close']!) continue;

      final date = _parseDate(cols[colIndex['Date']!]);
      if (date == null) continue;

      symbol ??= _cleanCode(cols[colIndex['Code']!]);

      // 調整済み終値を優先、なければ終値
      final closeRaw = colIndex.containsKey('AdjustmentClose')
          ? cols[colIndex['AdjustmentClose']!]
          : cols[colIndex['Close']!];
      final close = double.tryParse(closeRaw.replaceAll('"', '').trim());
      if (close == null || close <= 0) continue;

      final open = _parseDouble(cols, colIndex['AdjustmentOpen'] ?? colIndex['Open']);
      final high = _parseDouble(cols, colIndex['AdjustmentHigh'] ?? colIndex['High']);
      final low = _parseDouble(cols, colIndex['AdjustmentLow'] ?? colIndex['Low']);
      final volume = _parseInt(cols, colIndex['AdjustmentVolume'] ?? colIndex['Volume']);

      candles.add(Candle(
        date: date,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));
    }

    if (symbol == null || candles.isEmpty) {
      return _error('データが見つかりませんでした。ファイルの内容を確認してください。');
    }

    if (candles.length < _minRows) {
      return _error(
        'データが少なすぎます（${candles.length}日分）。\n'
        '最低$_minRows日分のデータが必要です。',
      );
    }

    candles.sort((a, b) => a.date.compareTo(b.date));

    return JQuantsParseResult(
      symbol: symbol,
      candles: candles,
      firstDate: candles.first.date,
      lastDate: candles.last.date,
    );
  }

  Map<String, int>? _buildColumnIndex(List<String> header) {
    final index = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      index[header[i]] = i;
    }
    // 必須カラムが全て存在するか確認
    for (final col in _requiredColumns) {
      if (!index.containsKey(col)) return null;
    }
    return index;
  }

  String? _parseDate(String raw) {
    final s = raw.replaceAll('"', '').trim();
    // YYYY-MM-DD または YYYY/MM/DD
    final normalized = s.replaceAll('/', '-');
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(normalized)) {
      return normalized;
    }
    return null;
  }

  String _cleanCode(String raw) {
    // "72580" → "7258" のように末尾の0を除く場合がある（J-Quantsは5桁）
    final s = raw.replaceAll('"', '').trim();
    if (s.length == 5 && s.endsWith('0')) return s.substring(0, 4);
    return s;
  }

  double? _parseDouble(List<String> cols, int? idx) {
    if (idx == null || idx >= cols.length) return null;
    return double.tryParse(cols[idx].replaceAll('"', '').trim());
  }

  int? _parseInt(List<String> cols, int? idx) {
    if (idx == null || idx >= cols.length) return null;
    return int.tryParse(cols[idx].replaceAll('"', '').trim().split('.')[0]);
  }

  // CSV行をカンマ分割（ダブルクォート内のカンマを無視）
  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buf = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    result.add(buf.toString());
    return result;
  }

  JQuantsParseResult _error(String message) => JQuantsParseResult(
        symbol: '',
        candles: const [],
        firstDate: '',
        lastDate: '',
        error: message,
      );
}
