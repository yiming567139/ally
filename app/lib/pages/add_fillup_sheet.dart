import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/fuel_math.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// 记一笔加油 Bottom Sheet（仅升数录入，金额按默认油价折算只读展示）
/// 传入 existing 进入编辑模式
Future<void> showAddFillUpSheet(BuildContext context, {FillUp? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (c) => AddFillUpSheet(existing: existing),
  );
}

class AddFillUpSheet extends ConsumerStatefulWidget {
  final FillUp? existing;
  const AddFillUpSheet({super.key, this.existing});
  @override
  ConsumerState<AddFillUpSheet> createState() => _AddFillUpSheetState();
}

class _AddFillUpSheetState extends ConsumerState<AddFillUpSheet> {
  final _volumeCtrl = TextEditingController();
  final _odoCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _full = true;
  DateTime _time = DateTime.now();
  String? _odoWarn;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _volumeCtrl.text = _num(e.volumeL);
      _odoCtrl.text = _num(e.odometer);
      _noteCtrl.text = e.note ?? '';
      _full = e.isFullTank;
      _time = e.filledAt;
    }
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(activeVehicleProvider).value;
    final allFills = ref.watch(fillUpsProvider).value ?? const <FillUp>[];
    final price = ref.watch(defaultPriceProvider).value ?? 8.31;
    // 编辑模式下把自身排除出参照数据
    final fills = allFills.where((f) => f.id != widget.existing?.id).toList();
    final lastOdo = fills.isNotEmpty ? fills.first.odometer : null;

    final vol = double.tryParse(_volumeCtrl.text) ?? 0;
    final amount = vol > 0 ? vol * price : null;
    final canSave = vehicle != null && vol > 0 && double.tryParse(_odoCtrl.text) != null;

    // 本箱进度：当前里程 - 最近一次加满锚点里程，对照平均满箱续航
    final odo = double.tryParse(_odoCtrl.text);
    String? tankInfo;
    final anchorOdo = _lastAnchorOdo(fills);
    if (odo != null && anchorOdo != null && odo > anchorOdo) {
      final x = (odo - anchorOdo).round();
      final range = FuelMath.tankRange(FuelMath.computeSegments(fills, price));
      tankInfo = range.avg > 0
          ? '本箱已跑 $x km · 平均每箱 ${range.avg.round()} km'
          : '本箱已跑 $x km';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF232E3E), Color(0xFF18202C)]),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Y.outlineStrong)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Y.outlineStrong, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(widget.existing == null ? '记一笔加油' : '编辑加油记录',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(color: Y.surfaceHigh, border: Border.all(color: Y.outline), borderRadius: BorderRadius.circular(999)),
                child: Text(DateFormat('MM-dd HH:mm').format(_time), style: const TextStyle(fontSize: 12, color: Y.onSurface2)),
              ),
            ),
          ]),
          const SizedBox(height: 18),

          // 升数大输入
          TextField(
            controller: _volumeCtrl, autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(
              hintText: '0.0', hintStyle: TextStyle(color: Y.onSurface3),
              suffixText: 'L', suffixStyle: TextStyle(fontSize: 18, color: Y.onSurface3),
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
          Text(
            amount != null ? '≈ ¥${_fmt(amount)} · 按默认油价 ${_fmt(price)} 元/L 折算' : '输入升数 · 金额按设置默认油价折算',
            style: const TextStyle(fontSize: 12.5, color: Y.onSurface3),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: _field('里程表 km', TextField(
              controller: _odoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()]),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true,
                helperText: _odoWarn ?? tankInfo, helperStyle: const TextStyle(color: Y.primary, fontSize: 11),
                hintText: lastOdo != null ? '$lastOdo' : '首次录入',
                hintStyle: const TextStyle(color: Y.onSurface3),
              ),
              onChanged: (v) {
                final o = double.tryParse(v);
                setState(() {
                  // 仅新增模式提示「里程回退」；编辑历史记录时里程天然小于最新记录
                  _odoWarn = (widget.existing == null && o != null && lastOdo != null && o < lastOdo)
                      ? '小于上次 $lastOdo，请确认没抄错' : null;
                });
              },
            ))),
            const SizedBox(width: 10),
            Expanded(child: _field('本次金额', Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(amount != null ? '≈¥${_fmt(amount)}' : '—',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500,
                      color: Y.onSurface2, fontFeatures: [FontFeature.tabularFigures()])),
            ))),
          ]),
          const SizedBox(height: 12),

          // 加满开关
          Container(
            decoration: BoxDecoration(
              color: _full ? Y.primarySoft : Y.surfaceHigh,
              border: Border.all(color: _full ? Y.primaryLine : Y.outline),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: Y.primary.withValues(alpha: .18), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.water_drop, size: 16, color: Y.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('加满油箱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('未加满将不计入区间油耗', style: TextStyle(fontSize: 11, color: Y.onSurface3)),
              ])),
              Switch(value: _full, activeThumbColor: Y.primary, onChanged: (v) => setState(() => _full = v)),
            ]),
          ),
          const SizedBox(height: 12),

          _field('备注（选填）', TextField(
            controller: _noteCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, hintText: '＋ 点击添加', hintStyle: TextStyle(color: Y.onSurface3)),
          )),
          const SizedBox(height: 18),

          YPrimaryButton(
            label: widget.existing == null ? '保存加油记录' : '保存修改',
            icon: Icons.local_gas_station,
            onPressed: canSave ? () => _save(vehicle, vol) : null,
          ),
        ])),
      ),
    );
  }

  Widget _field(String label, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0x8C0B0F16), border: Border.all(color: Y.outline),
      borderRadius: BorderRadius.circular(Y.rCtl),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10.5, color: Y.onSurface3, letterSpacing: 1)),
      const SizedBox(height: 2),
      child,
    ]),
  );

  Future<void> _pickTime() async {
    final d = await showDatePicker(context: context, initialDate: _time, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_time));
    setState(() => _time = DateTime(d.year, d.month, d.day, t?.hour ?? _time.hour, t?.minute ?? _time.minute));
  }

  /// 最近一次加满锚点的里程（编辑时排除自身）
  double? _lastAnchorOdo(List<FillUp> fills) {
    double? o;
    DateTime? t;
    for (final f in fills) {
      if (!f.isFullTank) continue;
      if (t == null || f.filledAt.isAfter(t)) {
        t = f.filledAt;
        o = f.odometer;
      }
    }
    return o;
  }

  Future<void> _save(Vehicle v, double vol) async {
    final db = ref.read(dbProvider);
    final note = _noteCtrl.text.trim();
    final odo = double.parse(_odoCtrl.text);
    if (widget.existing != null) {
      await (db.update(db.fillUps)..where((f) => f.id.equals(widget.existing!.id))).write(FillUpsCompanion(
        filledAt: drift.Value(_time),
        odometer: drift.Value(odo),
        isFullTank: drift.Value(_full),
        volumeL: drift.Value(vol),
        note: drift.Value(note.isEmpty ? null : note),
        updatedAt: drift.Value(DateTime.now()),
      ));
    } else {
      await db.addFillUp(FillUpsCompanion.insert(
        vehicleId: v.id,
        filledAt: _time,
        odometer: odo,
        isFullTank: _full,
        volumeL: vol,
        note: drift.Value(note.isEmpty ? null : note),
      ));
    }
    if (mounted) {
      // 先取 messenger 再 pop，避免在已销毁的 sheet context 上查祖先
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      HapticFeedback.lightImpact();
      messenger.showSnackBar(SnackBar(
        content: Text(widget.existing != null ? '已更新加油记录' : '已保存加油记录'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  String _fmt(double n) => n.toStringAsFixed(2);
}
