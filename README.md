# カブシミュ - 株式投資シミュレーター

中学1年生向け、過去の実際の株価データを使ったiPad向け有料Flutterアプリ。

## セットアップ

### 1. Flutter インストール

```bash
flutter --version  # 3.22以上が必要
```

### 2. 依存パッケージ取得 & コード生成

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. サンプルデータのみで起動（即プレイ可能）

```bash
flutter run
```

アプリ内蔵の「ミライテック株式会社」サンプルデータで即プレイできます。

### 4. 実データの追加（J-Quants）

1. [J-Quants](https://jpx-jquants.com/) に無料登録
2. 株価CSVをダウンロード
3. アプリ内「データを読み込む」からインポート

### 5. サンプルデータ生成（開発者向け）

```bash
dart scripts/generate_sample_data.dart
```

`assets/data/sample_prices.csv` を生成します（ミライテック社の架空株価データ）。

## プロジェクト構造

```
lib/
├── core/         # テーマ・ルーター・定数
├── data/         # DB・モデル・リポジトリ
├── presentation/ # 画面・ウィジェット・プロバイダー
└── services/     # シミュレーションエンジン・バッジ・AIコメント
assets/
├── data/         # companies.json, news_events.json, missions.json
└── images/       # ロゴ・キャラクター画像
scripts/
├── generate_sample_data.dart  # サンプルCSV生成
└── setup_after_flutter.ps1    # 初回セットアップ
```

## 技術スタック

| 用途 | パッケージ |
|------|----------|
| 状態管理 | flutter_riverpod |
| ナビゲーション | go_router |
| ローカルDB | drift + sqlite3 |
| チャート | CustomPainter（独自実装） |
| アニメーション | lottie + flutter_animate |
| ファイル選択 | file_picker |
