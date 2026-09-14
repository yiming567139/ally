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

/// 设置项
final defaultPriceProvider = StreamProvider<double>((ref) async* {
  final db = ref.watch(dbProvider);
  yield (await db.getSetting('default_price_per_l')) != null
      ? double.parse((await db.getSetting('default_price_per_l'))!)
      : 8.31;
});
final unitL100Provider = StreamProvider<bool>((ref) async* {
  final db = ref.watch(dbProvider);
  yield (await db.getSetting('unit_l100')) != '0'; // 默认 L/100km
});

/// 主题偏好（当前仅深色实现，浅色二期提供）
final themeModeProvider = StreamProvider<String>((ref) async* {
  yield await ref.watch(dbProvider).getSetting('theme_mode') ?? 'dark';
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
