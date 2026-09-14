import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:youji/data/database.dart';
import 'package:youji/data/providers.dart';
import 'package:youji/pages/home_page.dart';

/// 首页冒烟：内存库 + 3 笔演示数据，验证核心指标渲染
void main() {
  testWidgets('首页卡片按满箱法正确渲染', (tester) async {
    final db = AppDatabase.inMemory();
    await db.addVehicle('春风 450SR', '95#');
    await db.setSetting('default_price_per_l', '8.31');
    final v = (await db.select(db.vehicles).get()).first;
    await db.addFillUp(FillUpsCompanion.insert(
        vehicleId: v.id, filledAt: DateTime(2025, 5, 4, 17, 20), odometer: 3520, isFullTank: true, volumeL: 10.0));
    await db.addFillUp(FillUpsCompanion.insert(
        vehicleId: v.id, filledAt: DateTime(2025, 5, 18, 8, 33), odometer: 3780, isFullTank: true, volumeL: 9.2));
    await db.addFillUp(FillUpsCompanion.insert(
        vehicleId: v.id, filledAt: DateTime(2025, 5, 31, 19, 47), odometer: 4030, isFullTank: true, volumeL: 9.0));

    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      activeVehicleIdProvider.overrideWith((_) => v.id),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: HomePage())),
    );
    // 固定次数 pump 代替 pumpAndSettle（后者会被 drift 流持续调度帧挂死）
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // 段1: 3520→3780, 9.2L → 3.538；段2: 3780→4030, 9.0L → 3.60
    // 平均 = 18.2/510*100 = 3.5686 → 3.57
    expect(find.text('3.57').evaluate().isNotEmpty, isTrue, reason: '平均油耗 3.57 应渲染');
    expect(find.text('春风 450SR').evaluate().isNotEmpty, isTrue, reason: '车辆名应渲染');
    expect(find.text('满箱续航').evaluate().isNotEmpty, isTrue, reason: '满箱续航卡片应渲染');
    expect(find.text('255').evaluate().isNotEmpty, isTrue, reason: '纯段均值 255 应渲染');
    expect(find.text('261').evaluate().isNotEmpty, isFalse, reason: '261 不应出现（只有 3 笔，纯段均 255）');

    // 手动关库：addTearDown 里的 drift close() 在 flutter test 会挂起
    await db.close();
  });
}
