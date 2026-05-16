import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class Company {
  final String symbol;
  final String nameJa;
  final String category;
  final String descriptionJa;
  final String funFact;
  final String logoAsset;
  final String colorHex;
  final bool isSample;

  const Company({
    required this.symbol,
    required this.nameJa,
    required this.category,
    required this.descriptionJa,
    required this.funFact,
    required this.logoAsset,
    required this.colorHex,
    this.isSample = false,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color get categoryColor =>
      AppColors.categoryColors[category] ?? AppColors.primary;

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        symbol: json['symbol'] as String,
        nameJa: json['nameJa'] as String,
        category: json['category'] as String,
        descriptionJa: json['descriptionJa'] as String,
        funFact: json['funFact'] as String,
        logoAsset: json['logoAsset'] as String,
        colorHex: json['color'] as String,
        isSample: json['isSample'] as bool? ?? false,
      );

  // 架空企業サンプル
  static const Company sample = Company(
    symbol: '0001',
    nameJa: 'ミライテック株式会社',
    category: 'サンプル',
    descriptionJa: 'アプリに内蔵されたサンプル企業です。実在しません。',
    funFact: '架空の会社だけど、株価の動きはリアルと同じ仕組みで作られているよ！',
    logoAsset: 'assets/images/company_logos/sample.png',
    colorHex: '607D8B',
    isSample: true,
  );
}
