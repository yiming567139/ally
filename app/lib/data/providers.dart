import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';

/// 数据库单例
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 当前激活车辆（默认第一辆）
final activeVehicleIdProvider = StateProvider<int?>((ref) => null);

final activeVehicleProvider = StreamProvider<Vehicle?>((ref) {
  final db = ref.watch(dbProvider);
  final id = ref.watch(activeVehicleIdProvider);
  return db.watchActiveVehicle(id);
});

final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  return ref.watch(dbProvider).watchVehicles();
});

/// 当前车辆的全部加油记录
final fillUpsProvider = StreamProvider<List<FillUp>>((ref) {
  final v = ref.watch(activeVehicleProvider).value;
  if (v == null) return Stream.value(const <FillUp>[]);
  return ref.watch(dbProvider).watchFillUps(v.id);
});

/// 设置项（drift watch 流，改设置后 UI 自动刷新，无需手动 invalidate）
final defaultPriceProvider = StreamProvider<double>((ref) {
  return ref.watch(dbProvider).watchSetting('default_price_per_l')
      .map((v) => v != null ? (double.tryParse(v) ?? 8.31) : 8.31);
});
final unitL100Provider = StreamProvider<bool>((ref) {
  return ref.watch(dbProvider).watchSetting('unit_l100')
      .map((v) => v != '0'); // 默认 L/100km
});

/// 主题偏好（当前仅深色实现，浅色二期提供）
final themeModeProvider = StreamProvider<String>((ref) {
  return ref.watch(dbProvider).watchSetting('theme_mode')
      .map((v) => v ?? 'dark');
});

/// 每辆车的记录条数
final vehicleCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  ref.watch(vehiclesProvider);
  ref.watch(fillUpsProvider);
  return ref.read(dbProvider).vehicleFillCounts();
});

/// 切换当前车辆并持久化到设置表
Future<void> setActiveVehicle(WidgetRef ref, int id) async {
  ref.read(activeVehicleIdProvider.notifier).state = id;
  await ref.read(dbProvider).setSetting('active_vehicle_id', '$id');
}

/// 清除当前车辆选择（删车时调用）
Future<void> clearActiveVehicle(WidgetRef ref) async {
  ref.read(activeVehicleIdProvider.notifier).state = null;
  await ref.read(dbProvider).setSetting('active_vehicle_id', '');
}
