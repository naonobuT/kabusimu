import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ブランドカラー
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color accent = Color(0xFFFFB300);

  // 株価色（日本式: 陽線=赤、陰線=青）
  static const Color candleUp = Color(0xFFE53935);
  static const Color candleDown = Color(0xFF1E88E5);
  static const Color candleWick = Color(0xFF757575);

  // 損益色
  static const Color profit = Color(0xFFE53935);
  static const Color loss = Color(0xFF1E88E5);
  static const Color neutral = Color(0xFF757575);

  // 背景
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color chartBackground = Color(0xFF1A1A2E);

  // テキスト
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // カテゴリカラー
  static const Map<String, Color> categoryColors = {
    'ゲーム・エンタメ': Color(0xFF9C27B0),
    'エンタメ・レジャー': Color(0xFFE91E63),
    '食べ物・飲み物': Color(0xFFFF5722),
    'くらし・ショッピング': Color(0xFF4CAF50),
    'テクノロジー': Color(0xFF2196F3),
    'のりもの': Color(0xFF795548),
    '医療・未来': Color(0xFF00BCD4),
    'エネルギー': Color(0xFFFFC107),
    'サンプル': Color(0xFF9E9E9E),
  };
}
