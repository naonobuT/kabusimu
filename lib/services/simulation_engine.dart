import 'dart:async';

typedef OnTick = void Function(int newIndex);
typedef OnFinished = void Function();

class SimulationEngine {
  Timer? _timer;
  int _speedMultiplier = 1;
  bool _isPaused = true;

  // ミリ秒/ティック（1日分）
  static const Map<int, int> _tickMs = {
    1: 1000,
    3: 333,
    10: 100,
  };

  final OnTick onTick;
  final OnFinished onFinished;
  int _currentIndex = 0;
  int _maxIndex = 0;

  SimulationEngine({
    required this.onTick,
    required this.onFinished,
  });

  void init(int maxIndex, {int startIndex = 0}) {
    _maxIndex = maxIndex;
    _currentIndex = startIndex;
  }

  void play(int currentIndex) {
    _currentIndex = currentIndex;
    _isPaused = false;
    _startTimer();
  }

  void pause() {
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
  }

  void togglePlayPause(int currentIndex) {
    if (_isPaused) {
      play(currentIndex);
    } else {
      pause();
    }
  }

  void cycleSpeed() {
    final speeds = [1, 3, 10];
    final currentIdx = speeds.indexOf(_speedMultiplier);
    _speedMultiplier = speeds[(currentIdx + 1) % speeds.length];
    if (!_isPaused) {
      _timer?.cancel();
      _startTimer();
    }
  }

  int get speedMultiplier => _speedMultiplier;
  bool get isPaused => _isPaused;

  // 1ヶ月分（約21営業日）スキップ
  // advanceDay は毎回 +1 するため、21回 onTick を呼んで状態を合わせる
  void skipMonth() {
    final target = (_currentIndex + 21).clamp(0, _maxIndex);
    while (_currentIndex < target) {
      _currentIndex++;
      onTick(_currentIndex);
    }
    if (_currentIndex >= _maxIndex) {
      pause();
      onFinished();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final ms = _tickMs[_speedMultiplier] ?? 1000;
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (_isPaused) return;
      _currentIndex++;
      if (_currentIndex >= _maxIndex) {
        pause();
        onTick(_maxIndex - 1);
        onFinished();
        return;
      }
      onTick(_currentIndex);
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
