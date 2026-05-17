import 'package:flutter_test/flutter_test.dart';
import 'package:stock_simulator_kids/services/simulation_engine.dart';

void main() {
  group('SimulationEngine', () {
    test('初期化後は一時停止状態', () {
      final engine = SimulationEngine(
        onTick: (_) {},
        onFinished: () {},
      );
      engine.init(100);
      expect(engine.isPaused, isTrue);
      engine.dispose();
    });

    test('speedMultiplier は 1→3→10→1 と循環する', () {
      final engine = SimulationEngine(
        onTick: (_) {},
        onFinished: () {},
      );
      engine.init(100);
      expect(engine.speedMultiplier, 1);
      engine.cycleSpeed();
      expect(engine.speedMultiplier, 3);
      engine.cycleSpeed();
      expect(engine.speedMultiplier, 10);
      engine.cycleSpeed();
      expect(engine.speedMultiplier, 1);
      engine.dispose();
    });

    test('skipMonth は onTick を21回呼び最終インデックスは21になる', () {
      final ticks = <int>[];
      final engine = SimulationEngine(
        onTick: ticks.add,
        onFinished: () {},
      );
      engine.init(200, startIndex: 0);
      engine.skipMonth();
      expect(ticks.length, 21); // 21回 onTick が呼ばれる
      expect(ticks.last, 21);   // 最終インデックスは21
      engine.dispose();
    });

    test('maxIndex に達したら onFinished が呼ばれる', () {
      bool finished = false;
      final engine = SimulationEngine(
        onTick: (_) {},
        onFinished: () => finished = true,
      );
      engine.init(5, startIndex: 0);
      // 5回スキップして終端へ
      for (int i = 0; i < 5; i++) {
        engine.skipMonth();
      }
      expect(finished, isTrue);
      engine.dispose();
    });

    test('pause 後は isPaused == true', () {
      final engine = SimulationEngine(
        onTick: (_) {},
        onFinished: () {},
      );
      engine.init(100);
      engine.play(0);
      engine.pause();
      expect(engine.isPaused, isTrue);
      engine.dispose();
    });

    test('skipMonth 中に pause が呼ばれると残りのスキップを中断する', () {
      final ticks = <int>[];
      late SimulationEngine engine;
      engine = SimulationEngine(
        onTick: (index) {
          ticks.add(index);
          // 5回目のティックでpause（ニュースイベント発火を模倣）
          if (index == 5) engine.pause();
        },
        onFinished: () {},
      );
      engine.init(200, startIndex: 0);
      engine.skipMonth();
      // index=5でpauseが呼ばれた後は中断 → ticks = [1,2,3,4,5]
      expect(ticks.length, 5);
      expect(ticks.last, 5);
      engine.dispose();
    });
  });
}
