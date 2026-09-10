import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Vehicles, FillUps, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'youji.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // ---------- 车辆 ----------
  Stream<List<Vehicle>> watchVehicles() =>
      (select(vehicles)..orderBy([(u) => OrderingTerm.asc(u.id)])).watch();
  Stream<Vehicle?> watchActiveVehicle(int? id) {
    final q = select(vehicles);
    if (id != null) q.where((v) => v.id.equals(id));
    q.limit(1);
    return q.watchSingleOrNull();
  }
  Future<int> addVehicle(String name, String fuelGrade) =>
      into(vehicles).insert(VehiclesCompanion.insert(name: name, fuelGrade: fuelGrade));
  Future<void> deleteVehicle(int id) =>
      (delete(vehicles)..where((v) => v.id.equals(id))).go(); // 级联清空该车记录

  // ---------- 加油记录 ----------
  Stream<List<FillUp>> watchFillUps(int vehicleId) =>
      (select(fillUps)..where((f) => f.vehicleId.equals(vehicleId))
        ..orderBy([(f) => OrderingTerm.desc(f.filledAt)])).watch();
  Future<int> addFillUp(FillUpsCompanion entry) => into(fillUps).insert(entry);
  Future<void> deleteFillUp(int id) =>
      (delete(fillUps)..where((f) => f.id.equals(id))).go();
  Future<int> clearAllFillUps() => delete(fillUps).go(); // 保留车辆

  // ---------- 设置 ----------
  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }
  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(Setting(key: key, value: value));
}
