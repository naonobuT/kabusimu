import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/simulation_session.dart';

class PlaybackControls extends StatelessWidget {
  final SimulationStatus status;
  final int speedMultiplier;
  final String? currentDate;
  final VoidCallback onPlayPause;
  final VoidCallback onSpeedChange;
  final VoidCallback onSkip;

  const PlaybackControls({
    super.key,
    required this.status,
    required this.speedMultiplier,
    this.currentDate,
    required this.onPlayPause,
    required this.onSpeedChange,
    required this.onSkip,
  });

  bool get isPlaying => status == SimulationStatus.playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 日付表示
          if (currentDate != null)
            Text(
              currentDate!,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'monospace'),
            ),
          const Spacer(),
          // 速度
          _SpeedButton(
            label: '${speedMultiplier}x',
            onTap: onSpeedChange,
          ),
          const SizedBox(width: 12),
          // 再生/一時停止
          _ControlButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 40,
            onTap: onPlayPause,
            isPrimary: true,
          ),
          const SizedBox(width: 12),
          // スキップ（1ヶ月分）
          _ControlButton(
            icon: Icons.skip_next_rounded,
            size: 32,
            onTap: onSkip,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 16,
        height: size + 16,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SpeedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
