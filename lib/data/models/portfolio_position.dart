class PortfolioPosition {
  final String symbol;
  final String companyNameJa;
  final int shares;
  final double avgPrice;
  final double currentPrice;

  const PortfolioPosition({
    required this.symbol,
    required this.companyNameJa,
    required this.shares,
    required this.avgPrice,
    required this.currentPrice,
  });

  double get marketValue => shares * currentPrice;
  double get costBasis => shares * avgPrice;
  double get unrealizedPnl => marketValue - costBasis;
  double get unrealizedPnlPct =>
      costBasis == 0 ? 0 : (unrealizedPnl / costBasis) * 100;
  bool get isProfit => unrealizedPnl >= 0;

  PortfolioPosition copyWith({double? currentPrice}) => PortfolioPosition(
        symbol: symbol,
        companyNameJa: companyNameJa,
        shares: shares,
        avgPrice: avgPrice,
        currentPrice: currentPrice ?? this.currentPrice,
      );
}
