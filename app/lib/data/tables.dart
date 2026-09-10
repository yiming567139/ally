import 'package:drift/drift.dart';

/// 车辆表：只维护 车型号 + 所加油品
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();                    // 车型号
  TextColumn get fuelGrade => text()();               // 所加油品 92/95/98
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 加油记录表：录入只填升数，金额由全局默认油价折算
class FillUps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get filledAt => dateTime()();        // 加油时间，默认现在
  RealColumn get odometer => real()();                // 总里程读数
  BoolColumn get isFullTank => boolean()();           // 是否加满（计算边界开关）
  RealColumn get volumeL => real()();                 // 升数（唯一录入量值）
  RealColumn get distanceSinceLast => real().nullable()(); // 无总里程表的兜底
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 键值设置表：default_price_per_l / unit_l100 / theme_mode
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
