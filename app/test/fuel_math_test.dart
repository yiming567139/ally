import 'package:flutter_test/flutter_test.dart';
import '../lib/data/database.dart';
import '../lib/data/fuel_math.dart';

void main() {
  FillUp f(int id, double odo, double vol, bool full) => FillUp(
        id: id, vehicleId: 1, filledAt: DateTime(2025, 1, id), odometer: odo,
        isFullTank: full, volumeL: vol, note: null, photoPath: null,
        createdAt: DateTime(2025), updatedAt: DateTime(2025),
      );

  test('满箱法：只算加满锚点段，未加满只参与油量累计', () {
    final records = [
      f(1, 3520, 10.0, true),   // 基准
      f(2, 3780, 9.2, true),    // 段1: 260km / 9.2L = 3.54
      f(3, 4030, 4.0, false),   // 部分加油，不算锚点
      f(4, 4290, 5.5, true),    // 段2: 510km / 9.5L = 1.86（含部分 4L）
    ];
    final segs = FuelMath.computeSegments(records, 8.31);
    expect(segs.length, 2);
    expect(segs.last.l100, closeTo(3.538, 0.01));   // 9.2/260*100（段列表新→旧，旧段在末尾）
    expect(segs.first.l100, closeTo(1.863, 0.01));  // 9.5/510*100（含部分 4L，有补加）
    expect(segs.first.hasPartial, true);            // 段2 混入部分加油
    expect(segs.last.hasPartial, false);            // 段1 纯满箱
    expect(FuelMath.tankRange(segs).count, 1);      // 只有段1是纯段
  });

  test('平均油耗 = 总油量/总里程，金额按默认价折算', () {
    final records = [f(1, 1000, 10.0, true), f(2, 1100, 5.0, true)];
    final segs = FuelMath.computeSegments(records, 8.31);
    expect(FuelMath.avgL100(segs), closeTo(5.0, 0.001));
    expect(segs.first.cost, closeTo(5.0 * 8.31, 0.001));
    expect(segs.first.costPerKm, closeTo(5.0 * 8.31 / 100, 0.001));
  });

  test('里程倒退的段被跳过', () {
    // 排序后 1900(2) 在 2000(1) 之前：1900→2000 是合法段（100km），2000→2200 也是（200km）
    final records = [f(1, 2000, 8.0, true), f(2, 1900, 8.0, true), f(3, 2200, 8.0, true)];
    final segs = FuelMath.computeSegments(records, 8.31);
    expect(segs.length, 2);
    expect(segs.map((s) => s.dist).toSet(), {100, 200});
  });

  test('尾部未加满不产生区间油耗', () {
    final records = [f(1, 1000, 10.0, true), f(2, 1200, 3.0, false)];
    expect(FuelMath.computeSegments(records, 8.31).length, 0);
  });
}
