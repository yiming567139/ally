import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'dart:io';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Vehicles, FillUps, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用：内存数据库（直接调 sqlite3 包，绕过平台插件，flutter test 可用）
  AppDatabase.inMemory() : super(NativeDatabase.opened(sqlite3.sqlite3.openInMemory()));

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
    final q = select(vehicles)..orderBy([(v) => OrderingTerm.asc(v.id)]);
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

  /// 每辆车的记录条数
  Future<Map<int, int>> vehicleFillCounts() async {
    final rows = await select(fillUps).get();
    final m = <int, int>{};
    for (final r in rows) {
      m[r.vehicleId] = (m[r.vehicleId] ?? 0) + 1;
    }
    return m;
  }

  // ---------- 备份 / 恢复 ----------
  /// 导出全部数据为 JSON Map（与存储格式无关，跨版本安全）
  Future<Map<String, dynamic>> exportAll() async {
    final vs = await select(vehicles).get();
    final fs = await select(fillUps).get();
    final ss = await select(settings).get();
    return {
      'app': 'youji',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': [
        for (final v in vs)
          {'id': v.id, 'name': v.name, 'fuelGrade': v.fuelGrade, 'createdAt': v.createdAt.toIso8601String()},
      ],
      'fillUps': [
        for (final f in fs)
          {
            'id': f.id,
            'vehicleId': f.vehicleId,
            'filledAt': f.filledAt.toIso8601String(),
            'odometer': f.odometer,
            'isFullTank': f.isFullTank,
            'volumeL': f.volumeL,
            'distanceSinceLast': f.distanceSinceLast,
            'note': f.note,
            'photoPath': f.photoPath,
            'createdAt': f.createdAt.toIso8601String(),
            'updatedAt': f.updatedAt.toIso8601String(),
          },
      ],
      'settings': [for (final s in ss) {'key': s.key, 'value': s.value}],
    };
  }

  /// 从 JSON Map 恢复（覆盖当前全部数据），保留原始 id
  Future<void> importAll(Map<String, dynamic> j) async {
    if (j['app'] != 'youji' || j['vehicles'] is! List || j['fillUps'] is! List) {
      throw const FormatException('不是有效的油迹备份文件');
    }
    final vs = (j['vehicles'] as List).cast<Map<String, dynamic>>();
    final fs = (j['fillUps'] as List).cast<Map<String, dynamic>>();
    final ss = ((j['settings'] as List?) ?? const []).cast<Map<String, dynamic>>();
    await transaction(() async {
      await delete(fillUps).go();
      await delete(vehicles).go();
      await delete(settings).go();
      await batch((b) {
        b.insertAll(vehicles, [
          for (final v in vs)
            VehiclesCompanion(
              id: Value(v['id'] as int),
              name: Value(v['name'] as String),
              fuelGrade: Value(v['fuelGrade'] as String),
              createdAt: Value(DateTime.parse(v['createdAt'] as String)),
            ),
        ]);
        b.insertAll(fillUps, [
          for (final f in fs)
            FillUpsCompanion(
              id: Value(f['id'] as int),
              vehicleId: Value(f['vehicleId'] as int),
              filledAt: Value(DateTime.parse(f['filledAt'] as String)),
              odometer: Value((f['odometer'] as num).toDouble()),
              isFullTank: Value(f['isFullTank'] as bool),
              volumeL: Value((f['volumeL'] as num).toDouble()),
              distanceSinceLast: Value(f['distanceSinceLast'] == null ? null : (f['distanceSinceLast'] as num).toDouble()),
              note: Value(f['note'] as String?),
              photoPath: Value(f['photoPath'] as String?),
              createdAt: Value(DateTime.parse(f['createdAt'] as String)),
              updatedAt: Value(DateTime.parse(f['updatedAt'] as String)),
            ),
        ]);
        b.insertAll(settings, [
          for (final s in ss) Setting(key: s['key'] as String, value: s['value'] as String),
        ]);
      });
    });
  }

  // ---------- 设置 ----------
  Future<String?> getSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }
  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(Setting(key: key, value: value));
}
