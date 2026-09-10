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
