import 'database.dart';

/// 满箱法计算服务（口径与 docs/设计文档.md 第 6 节一致）
/// 区间油耗只由「加满 → 加满」锚点段决定：(A, B] 段内油量 / 里程差

/// 一条计算段
class Segment {
  final FillUp from; // 上次加满（锚点，不含）
  final FillUp to;   // 本次加满（锚点，含）
  final double dist;
  final double fuel; // 升
  final double cost; // 元（volume × 默认单价）
  final bool hasPartial; // 段内是否有中途补加
  Segment({required this.from, required this.to, required this.dist, required this.fuel, required this.cost, required this.hasPartial});
  double get l100 => fuel / dist * 100;
  double get kmPerL => dist / fuel;
  double get costPerKm => cost / dist;
}

class FuelMath {
  /// 计算（records 需含全部历史；按设计文档以 filled_at 排序，里程作平局兜底）
  static List<Segment> computeSegments(List<FillUp> records, double defaultPrice) {
    final asc = [...records]..sort((a, b) {
      final t = a.filledAt.compareTo(b.filledAt);
      return t != 0 ? t : a.odometer.compareTo(b.odometer);
    });
    final out = <Segment>[];
    for (var i = 1; i < asc.length; i++) {
      final b = asc[i];
      if (!b.isFullTank) continue;
      var j = i - 1;
      while (j >= 0 && !asc[j].isFullTank) {
        j--;
      }
      if (j < 0) continue;
      final a = asc[j];
      final dist = b.odometer - a.odometer;
      if (dist <= 0) continue;
      var fuel = 0.0;
      var hasPartial = false;
      for (var k = j + 1; k <= i; k++) {
        fuel += asc[k].volumeL;
        if (!asc[k].isFullTank) hasPartial = true;
      }
      out.add(Segment(from: a, to: b, dist: dist, fuel: fuel, cost: fuel * defaultPrice, hasPartial: hasPartial));
    }
    return out.reversed.toList(); // 新 → 旧
  }

  /// 平均油耗 = 锚点后总油量 / 总里程 × 100
  static double avgL100(List<Segment> segs) {
    if (segs.isEmpty) return 0;
    final fuel = segs.fold(0.0, (s, x) => s + x.fuel);
    final dist = segs.fold(0.0, (s, x) => s + x.dist);
    return fuel / dist * 100;
  }

  /// 满箱续航：无中途补加的段里程均值 / 最近一箱 / 样本数
  static ({double avg, double? last, int count}) tankRange(List<Segment> segs) {
    final pure = segs.where((s) => !s.hasPartial).toList();
    if (pure.isEmpty) return (avg: 0, last: null, count: 0);
    final avg = pure.fold(0.0, (s, x) => s + x.dist) / pure.length;
    return (avg: avg, last: pure.first.dist, count: pure.length);
  }
}
