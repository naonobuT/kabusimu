import '../data/models/simulation_session.dart';

class AiCommentaryService {
  String generate(SimulationState finalState, List<String> earnedBadgeIds) {
    final ret = finalState.totalReturnPct;
    final companyName = _getFirstCompanyName(finalState);

    if (ret >= 50) return _bigWin(companyName, ret, earnedBadgeIds);
    if (ret >= 10) return _smallWin(companyName, ret, earnedBadgeIds);
    if (ret >= 0) return _tinyWin(companyName, ret, earnedBadgeIds);
    if (ret >= -10) return _smallLoss(companyName, ret, earnedBadgeIds);
    return _bigLoss(companyName, ret, earnedBadgeIds);
  }

  String _getFirstCompanyName(SimulationState state) {
    final symbol = state.session.selectedSymbols.firstOrNull ?? '';
    return state.positions[symbol]?.companyNameJa ?? '選択した会社';
  }

  String _bigWin(String name, double ret, List<String> badges) =>
      '🎉 すごい！${ret.toStringAsFixed(1)}%の大成功！\n'
      '$nameへの投資が大当たりしたね。\n'
      'でも、これは運だけじゃないかも。チャートをよく見ると、いいタイミングで買えていたことが分かるよ。\n'
      '長期でコツコツ持ち続ける「握力」が勝利の鍵だった！';

  String _smallWin(String name, double ret, List<String> badges) =>
      '👍 ${ret.toStringAsFixed(1)}%のプラスで終了！\n'
      '株式投資の平均リターンは年率3〜7%くらいと言われているから、これはなかなか優秀だよ！\n'
      '${badges.contains('iron_mind') ? '暴落に耐えた「鉄のメンタル」が光ったね！' : '次は分散投資にも挑戦してみよう。'}';

  String _tinyWin(String name, double ret, List<String> badges) =>
      '😊 ${ret.toStringAsFixed(1)}%でプラスフィニッシュ！\n'
      'わずかでも利益が出たのはすごいこと。\n'
      '銀行の普通預金（年率0.001%）よりずっといい結果だよ。\n'
      '次のステージで分散投資を試すと、もっと安定した結果が出るかも！';

  String _smallLoss(String name, double ret, List<String> badges) =>
      '😅 ${ret.toStringAsFixed(1)}%のマイナスで終了。\n'
      'でも大丈夫！これは「授業料」だよ。\n'
      'プロの投資家でも毎回勝てるわけじゃない。\n'
      '${badges.contains('long_term_investor') ? '一度も売らなかったのはとても大切な行動だよ。長期でみれば回復することも多い。' : '次は売るタイミングを少し変えてみよう。'}';

  String _bigLoss(String name, double ret, List<String> badges) =>
      '😬 ${ret.toStringAsFixed(1)}%の大きなマイナス…。\n'
      'でもこれはシミュレーション。リアルじゃなくてよかった！\n'
      'なぜこんなに下がったのか、チャートとニュースを見直してみよう。\n'
      'ヒント: 1つの会社に全部賭けるのは危険。次は「分散投資」ステージに挑戦してみて！';
}
