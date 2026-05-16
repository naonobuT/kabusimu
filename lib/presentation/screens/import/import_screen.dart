import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/local/app_database.dart';
import '../../../data/datasources/local/price_database.dart';
import '../../../services/jquants_csv_parser.dart';
import '../../providers/app_providers.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  int _currentStep = 0;
  bool _isImporting = false;
  JQuantsParseResult? _previewResult;
  String? _errorMessage;
  List<String> _importedSymbols = [];

  @override
  void initState() {
    super.initState();
    _loadImported();
  }

  Future<void> _loadImported() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await db.getImportedSymbols();
    setState(() {
      _importedSymbols = rows.map((r) => '${r.nameJa ?? r.symbol}（${r.rowCount}日分）').toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('データを読み込む（J-Quants）')),
      body: Column(
        children: [
          // インポート済み一覧
          if (_importedSymbols.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ インポート済みの銘柄',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.green)),
                  const SizedBox(height: 4),
                  ..._importedSymbols.map((s) => Text('• $s',
                      style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
          // ステップUI
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _currentStep < 2
                  ? () => setState(() => _currentStep++)
                  : null,
              onStepCancel: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              controlsBuilder: (context, details) => Row(
                children: [
                  if (_currentStep < 2)
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: const Text('次へ'),
                    ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('戻る'),
                    ),
                  ],
                ],
              ),
              steps: [
                _step1(),
                _step2(),
                _step3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Step _step1() => Step(
        title: const Text('J-Quantsに登録しよう'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'J-Quantsは日本取引所グループが提供する無料の株価データサービスです。\n'
              '登録（無料）すると、実際の日本株の過去データをダウンロードできます。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _InfoBox(
              emoji: '📝',
              text: '無料プランで十分です。クレジットカード不要で登録できます。',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://application.jpx-jquants.com/'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: const Text('J-Quantsサイトを開く'),
            ),
          ],
        ),
      );

  Step _step2() => Step(
        title: const Text('CSVをダウンロードしよう'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ログイン後、以下の手順でCSVをダウンロードしてください：',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _StepItem(number: '1', text: '「マーケット情報」→「株価データ（日次）」を選ぶ'),
            _StepItem(number: '2', text: '調べたい会社の銘柄コードを入力する'),
            _StepItem(number: '3', text: '期間を選んで「CSVダウンロード」ボタンを押す'),
            const SizedBox(height: 16),
            _InfoBox(
              emoji: '💡',
              text: '銘柄コード例：\n任天堂 → 7974\nソニー → 6758\nトヨタ → 7203',
            ),
            const SizedBox(height: 12),
            Text(
              'ダウンロードしたCSVファイルはiPadの「ファイル」アプリの「ダウンロード」フォルダに保存されます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );

  Step _step3() => Step(
        title: const Text('ファイルを読み込もう'),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ダウンロードしたCSVファイルを選択してください。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            if (_previewResult != null && _previewResult!.isSuccess)
              _PreviewCard(result: _previewResult!),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isImporting ? null : _pickAndPreview,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(_isImporting ? '読み込み中...' : 'CSVファイルを選ぶ'),
                ),
                if (_previewResult?.isSuccess == true) ...[
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isImporting ? null : _confirmImport,
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('追加する'),
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  Future<void> _pickAndPreview() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
      _previewResult = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'CSV'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final file = result.files.first;
      // ファイルサイズチェック（50MB上限）
      final fileSize = file.size;
      if (fileSize > 50 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'ファイルが大きすぎます（上限50MB）。別のファイルを選んでください。';
          _isImporting = false;
        });
        return;
      }

      String content;
      try {
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString(encoding: utf8);
        } else {
          setState(() {
            _errorMessage = 'ファイルを読み込めませんでした';
            _isImporting = false;
          });
          return;
        }
      } on FormatException {
        setState(() {
          _errorMessage = 'ファイルの文字コードがUTF-8ではありません。UTF-8形式のCSVを使用してください。';
          _isImporting = false;
        });
        return;
      }

      final parsed = JQuantsCsvParser().parse(content);
      setState(() {
        _previewResult = parsed;
        _errorMessage = parsed.isSuccess ? null : parsed.error;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isImporting = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    final parsed = _previewResult;
    if (parsed == null || !parsed.isSuccess) return;

    setState(() => _isImporting = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final priceDb = ref.read(priceDatabaseProvider);

      // price_table にバルクインサート
      await priceDb.batch((batch) {
        for (final candle in parsed.candles) {
          batch.insert(
            priceDb.priceTable,
            PriceTableCompanion.insert(
              symbol: parsed.symbol,
              date: candle.date,
              open: drift.Value(candle.open),
              high: drift.Value(candle.high),
              low: drift.Value(candle.low),
              close: candle.close,
              volume: drift.Value(candle.volume),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      });

      // imported_symbols に記録
      await db.upsertImportedSymbol(ImportedSymbolTableCompanion.insert(
        symbol: parsed.symbol,
        nameJa: drift.Value(parsed.symbol),
        firstDate: parsed.firstDate,
        lastDate: parsed.lastDate,
        rowCount: parsed.candles.length,
        importedAt: DateTime.now(),
      ));

      // キャッシュ無効化
      ref.read(companyRepositoryProvider).invalidateCache();
      ref.invalidate(companiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${parsed.symbol} のデータを追加しました（${parsed.candles.length}日分）'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _previewResult = null;
          _isImporting = false;
        });
        _loadImported();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存中にエラーが発生しました: $e';
        _isImporting = false;
      });
    }
  }
}

class _InfoBox extends StatelessWidget {
  final String emoji;
  final String text;
  const _InfoBox({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _PreviewCard extends StatelessWidget {
  final JQuantsParseResult result;
  const _PreviewCard({required this.result});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ 読み込み内容のプレビュー',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.green,
                    )),
            const SizedBox(height: 8),
            _row(context, '銘柄コード', result.symbol),
            _row(context, 'データ期間', '${result.firstDate} 〜 ${result.lastDate}'),
            _row(context, '取引日数', '${result.candles.length}日分'),
          ],
        ),
      );

  Widget _row(BuildContext context, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}
