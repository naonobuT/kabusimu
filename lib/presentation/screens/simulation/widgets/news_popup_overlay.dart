import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/news_event.dart';

class NewsPopupOverlay extends StatefulWidget {
  final NewsEvent? newsEvent;
  final VoidCallback onDismissed;

  const NewsPopupOverlay({
    super.key,
    required this.newsEvent,
    required this.onDismissed,
  });

  @override
  State<NewsPopupOverlay> createState() => _NewsPopupOverlayState();
}

class _NewsPopupOverlayState extends State<NewsPopupOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  int _dismissToken = 0; // 古いタイマーを無効化するためのトークン

  void _dismiss() {
    _dismissToken++; // 古いタイマーを無効化
    widget.onDismissed();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(NewsPopupOverlay old) {
    super.didUpdateWidget(old);
    if (widget.newsEvent != null && old.newsEvent == null) {
      _controller.forward(from: 0);
      // 4秒後に自動消去（トークンで古いタイマーを無効化）
      final token = ++_dismissToken;
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _dismissToken == token) _dismiss();
      });
    } else if (widget.newsEvent == null) {
      _dismissToken++;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newsEvent == null) return const SizedBox.shrink();

    final event = widget.newsEvent!;
    final isPositive = event.isPositive;
    final accentColor = isPositive ? AppColors.candleUp : AppColors.candleDown;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPositive ? '📈 プラス材料' : '📉 マイナス材料',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.date,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.titleJa,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.bodyJa,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
