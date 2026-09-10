import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = ref.watch(defaultPriceProvider).value ?? 8.31;
    final l100 = ref.watch(unitL100Provider).value ?? true;
    final vehicle = ref.watch(activeVehicleProvider).value;
    final fills = ref.watch(fillUpsProvider).value ?? const <FillUp>[];

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 40), children: [
        const YCaps('我的车辆'),
        const SizedBox(height: 10),
        if (vehicle != null) YCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          onTap: () => _editVehicle(context, ref, vehicle),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF374151), Color(0xFF1F2937)]),
                  border: Border.all(color: Y.outlineStrong), borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Text(vehicle.name.characters.first, style: const TextStyle(color: Y.primary, fontWeight: FontWeight.w600))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${vehicle.fuelGrade} 汽油 · ${fills.length} 条记录', style: const TextStyle(fontSize: 11, color: Y.onSurface3)),
            ])),
            const Icon(Icons.chevron_right, size: 15, color: Y.onSurface3),
          ]),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _editVehicle(context, ref, null),
          icon: const Icon(Icons.add, size: 16, color: Y.primary),
          label: const Text('添加车辆', style: TextStyle(color: Y.primary)),
        ),
        if (vehicle != null)
          TextButton.icon(
            onPressed: () => _deleteVehicle(context, ref, vehicle, fills.length),
            icon: const Icon(Icons.delete_outline, size: 16, color: Y.error),
            label: const Text('删除车辆（同时清空该车记录）', style: TextStyle(color: Y.error, fontSize: 13)),
          ),
        const SizedBox(height: 18),

        const YCaps('通用'),
        const SizedBox(height: 10),
        YCard(padding: EdgeInsets.zero, child: Column(children: [
          _row('常规默认油价', '所有金额按此折算，改价不影响历史记录', trailing: GestureDetector(
            onTap: () => _editPrice(context, ref, price),
            child: Text('${price.toStringAsFixed(2)} 元/L', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Y.primary)),
          )),
          const Divider(height: 1, indent: 16, color: Y.outline),
          _row('油耗单位', '副单位始终显示换算值', trailing: _seg(['L/100km', 'km/L'], l100 ? 0 : 1, (i) async {
            await ref.read(dbProvider).setSetting('unit_l100', i == 0 ? '1' : '0');
            ref.invalidate(unitL100Provider);
          })),
          const Divider(height: 1, indent: 16, color: Y.outline),
          _row('主题', '', trailing: _seg(['跟随', '深色', '浅色'], 1, (_) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('浅色主题二期提供，当前为深色优先设计')));
          })),
        ])),
        const SizedBox(height: 18),

        const YCaps('数据'),
        const SizedBox(height: 10),
        YCard(padding: EdgeInsets.zero, child: Column(children: [
          _row('导出 CSV', '全部加油记录，含区间油耗', trailing: const Icon(Icons.download, size: 16, color: Y.onSurface3),
              onTap: () => _exportCsv(context, ref)),
          const Divider(height: 1, indent: 16, color: Y.outline),
          _row('清空加油记录', '清空全部 ${fills.length} 条记录，车辆信息保留，不可恢复', danger: true,
              trailing: const Icon(Icons.delete_outline, size: 16, color: Y.error),
              onTap: () => _clearRecords(context, ref, fills.length)),
        ])),
        const SizedBox(height: 18),

        YCard(padding: EdgeInsets.zero, child: _row('关于油迹', 'v0.1 · 满箱法计算说明', trailing: const Icon(Icons.chevron_right, size: 15, color: Y.onSurface3),
            onTap: () => showAboutDialog(context: context, applicationName: '油迹 YouJi', applicationVersion: '0.1.0',
                children: [const Text('满箱法：仅「加满 → 加满」区间计算油耗，未加满记录不计边界。')]))),
        const SizedBox(height: 20),
        const Center(child: Text('数据仅保存在本机 · 油迹 YouJi', style: TextStyle(fontSize: 11, color: Y.onSurface3, height: 1.8))),
      ]),
    );
  }

  Widget _row(String t, String d, {Widget? trailing, VoidCallback? onTap, bool danger = false}) {
    return InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: danger ? Y.error : Y.onSurface)),
          if (d.isNotEmpty) ...[const SizedBox(height: 3), Text(d, style: const TextStyle(fontSize: 11, color: Y.onSurface3))],
        ])),
        if (trailing != null) trailing,
      ]),
    ));
  }

  Widget _seg(List<String> items, int on, ValueChanged<int> onTap) {
    return Container(
      decoration: BoxDecoration(color: const Color(0x990B0F16), border: Border.all(color: Y.outline), borderRadius: BorderRadius.circular(9)),
      padding: const EdgeInsets.all(2),
      child: Row(children: [for (var i = 0; i < items.length; i++)
        GestureDetector(onTap: () => onTap(i), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: i == on ? Y.surfaceHigh : Colors.transparent, borderRadius: BorderRadius.circular(7),
              border: i == on ? Border.all(color: Y.primaryLine) : null),
          child: Text(items[i], style: TextStyle(fontSize: 11, color: i == on ? Y.primary : Y.onSurface3, fontWeight: i == on ? FontWeight.w500 : FontWeight.w400)),
        )),
      ]),
    );
  }

  Future<void> _editVehicle(BuildContext context, WidgetRef ref, Vehicle? v) async {
    final nameCtrl = TextEditingController(text: v?.name);
    String grade = v?.fuelGrade ?? '95#';
    final ok = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, setS) => AlertDialog(
      title: Text(v == null ? '添加车辆' : '编辑车辆'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '车型号', hintText: '如：春风 450SR'), autofocus: true),
        const SizedBox(height: 16),
        Row(children: [const Text('所加油品'), const SizedBox(width: 16),
          ...['92#', '95#', '98#'].map((g) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(
            label: Text(g), selected: grade == g,
            selectedColor: Y.primarySoft, labelStyle: TextStyle(color: grade == g ? Y.primary : Y.onSurface2),
            onSelected: (_) => setS(() => grade = g),
          )))]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Y.primary, foregroundColor: Y.onPrimary),
            onPressed: () => Navigator.pop(c, nameCtrl.text.trim().isNotEmpty), child: const Text('保存')),
      ],
    )));
    if (ok == true) {
      final db = ref.read(dbProvider);
      if (v == null) {
        final id = await db.addVehicle(nameCtrl.text.trim(), grade);
        ref.read(activeVehicleIdProvider.notifier).state = id;
      } else {
        await (db.update(db.vehicles)..where((x) => x.id.equals(v.id))).write(
            VehiclesCompanion(name: drift.Value(nameCtrl.text.trim()), fuelGrade: drift.Value(grade)));
      }
    }
  }

  Future<void> _deleteVehicle(BuildContext context, WidgetRef ref, Vehicle v, int count) async {
    final ok = await yConfirm(context, title: '删除「${v.name}」？',
        body: '将同时清空该车的 $count 条加油记录，不可恢复。建议先到「数据 → 导出 CSV」备份。', danger: true);
    if (ok) {
      await ref.read(dbProvider).deleteVehicle(v.id);
      ref.read(activeVehicleIdProvider.notifier).state = null;
    }
  }

  Future<void> _editPrice(BuildContext context, WidgetRef ref, double cur) async {
    final ctrl = TextEditingController(text: cur.toStringAsFixed(2));
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('常规默认油价'),
      content: TextField(controller: ctrl, autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: '元/L', helperText: '所有金额按此折算，改价不影响历史记录')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Y.primary, foregroundColor: Y.onPrimary),
            onPressed: () => Navigator.pop(c, true), child: const Text('保存')),
      ],
    ));
    if (ok == true) {
      final v = double.tryParse(ctrl.text);
      if (v != null && v > 0) {
        await ref.read(dbProvider).setSetting('default_price_per_l', v.toString());
        ref.invalidate(defaultPriceProvider);
      }
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final vehicles = await db.select(db.vehicles).get();
    final lines = ['车辆,时间,里程表(km),是否加满,升数(L),备注'];
    for (final v in vehicles) {
      final fs = await (db.select(db.fillUps)..where((f) => f.vehicleId.equals(v.id))).get();
      for (final f in fs) {
        lines.add('${v.name},${f.filledAt.toIso8601String()},${f.odometer},${f.isFullTank ? '满' : '部分'},${f.volumeL},${f.note ?? ''}');
      }
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/youji-export-${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(lines.join('\n'));
    await Share.shareXFiles([XFile(file.path)], subject: '油迹 · 加油记录导出');
  }

  Future<void> _clearRecords(BuildContext context, WidgetRef ref, int count) async {
    final ok = await yConfirm(context, title: '清空加油记录？',
        body: '将清空全部 $count 条加油记录（所有车辆），车辆信息保留，不可恢复。建议先备份。', danger: true);
    if (ok) {
      await ref.read(dbProvider).clearAllFillUps();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清空加油记录')));
    }
  }
}
