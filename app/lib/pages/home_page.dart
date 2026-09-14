import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/fuel_math.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

final _fmt = NumberFormat('#,##0.00');
final _fmt1 = NumberFormat('#,##0.0');

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(activeVehicleProvider).value;
    final fills = ref.watch(fillUpsProvider).value ?? const <FillUp>[];
    final price = ref.watch(defaultPriceProvider).value ?? 8.31;
    final l100Mode = ref.watch(unitL100Provider).value ?? true;

    final segs = FuelMath.computeSegments(fills, price);
    final avg = FuelMath.avgL100(segs);
    final range = FuelMath.tankRange(segs);
    final latest = segs.isNotEmpty ? segs.first : null;
    final lastFill = fills.isNotEmpty ? fills.first : null;

    // 本月
    final now = DateTime.now();
    final monthVol = fills
        .where((f) => f.filledAt.year == now.year && f.filledAt.month == now.month)
        .fold(0.0, (s, f) => s + f.volumeL);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          children: [
            // ---- 车辆头 ----
            Row(children: [
              GestureDetector(
                onTap: () => _pickVehicle(context, ref),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF374151), Color(0xFF1F2937)]),
                      border: Border.all(color: Y.outlineStrong),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(vehicle?.name.isNotEmpty == true ? vehicle!.name.characters.first : '—',
                        style: const TextStyle(color: Y.primary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(vehicle?.name ?? '未选择车辆',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(vehicle != null ? '${vehicle.fuelGrade} 汽油' : '先去设置里添加',
                        style: const TextStyle(fontSize: 11, color: Y.onSurface3)),
                  ]),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: Y.onSurface3),
                ]),
              ),
            ]),
            const SizedBox(height: 14),

            // ---- 油耗大数字 ----
            Center(child: Column(children: [
              const YCaps('当前平均油耗 / AVG CONSUMPTION'),
              const SizedBox(height: 8),
              Text(avg > 0 ? _fmt.format(avg) : '—', style: YText.display),
              const SizedBox(height: 8),
              Text(
                avg > 0
                    ? (l100Mode ? 'L / 100km　·　${_fmt1.format(100 / avg)} km/L' : 'km/L　·　${_fmt.format(avg)} L/100km')
                    : '先记两笔加满，算出第一组油耗',
                style: const TextStyle(fontSize: 14, color: Y.onSurface3, letterSpacing: 1),
              ),
              if (latest != null && avg > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Y.successSoft, borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Y.success.withValues(alpha: .25)),
                  ),
                  child: Text(
                    '${latest.l100 <= avg ? '▾' : '▴'} 最新区间 ${_fmt.format(latest.l100)} · ${latest.l100 <= avg ? '低于' : '高于'}均值 ${(100 * (latest.l100 - avg) / avg).abs().toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Y.success),
                  ),
                ),
              ],
            ])),
            const SizedBox(height: 20),

            // ---- 满箱续航 ----
            YCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('满箱续航', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('按无中途补加的段实测', style: TextStyle(fontSize: 11, color: Y.onSurface3, fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _stat('平均每箱', range.avg > 0 ? '${range.avg.round()}' : '—', 'km', amber: true),
                _stat('最近一箱', range.last != null ? '${range.last!.round()}' : '—', 'km'),
                _stat('统计样本', '${range.count}', '段', last: true),
              ]),
            ])),
            const SizedBox(height: 14),

            // ---- 本月 / 每公里成本 ----
            Row(children: [
              Expanded(child: YCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [Icon(Icons.payments_outlined, size: 13, color: Y.onSurface3), SizedBox(width: 6),
                    Text('本月油费', style: TextStyle(fontSize: 11, color: Y.onSurface3))]),
                const SizedBox(height: 8),
                Text('¥${_fmt1.format(monthVol * price)}',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 6),
                Text('· 本月进行中', style: TextStyle(fontSize: 11, color: Y.success)),
              ]))),
              const SizedBox(width: 12),
              Expanded(child: YCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [Icon(Icons.route_outlined, size: 13, color: Y.onSurface3), SizedBox(width: 6),
                    Text('每公里成本', style: TextStyle(fontSize: 11, color: Y.onSurface3))]),
                const SizedBox(height: 8),
                Text(latest != null ? '¥${_fmt.format(latest.costPerKm)}' : '—',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 6),
                Text('按默认油价 ${_fmt.format(price)} 元/L 折算',
                    style: const TextStyle(fontSize: 11, color: Y.onSurface3)),
              ]))),
            ]),
            const SizedBox(height: 14),

            // ---- 上次加油 ----
            if (lastFill != null)
              YCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Y.primarySoft, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Y.primaryLine)),
                    child: const Icon(Icons.local_gas_station, size: 17, color: Y.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('上次加油', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('${DateFormat('MM-dd HH:mm').format(lastFill.filledAt)} · ${lastFill.volumeL}L',
                        style: const TextStyle(fontSize: 11.5, color: Y.onSurface3)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('¥${_fmt.format(lastFill.volumeL * price)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
                    if (latest != null)
                      Text('区间 ${_fmt.format(latest.l100)} L/100km',
                          style: const TextStyle(fontSize: 11, color: Y.onSurface3)),
                  ]),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String k, String v, String unit, {bool amber = false, bool last = false}) {
    return Expanded(child: Container(
      margin: EdgeInsets.only(right: last ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x8C0B0F16), border: Border.all(color: Y.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: const TextStyle(fontSize: 10.5, color: Y.onSurface3, letterSpacing: .8)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
              color: amber ? Y.primary : Y.onSurface, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 3),
          Text(unit, style: const TextStyle(fontSize: 10, color: Y.onSurface3)),
        ]),
      ]),
    ));
  }

  void _pickVehicle(BuildContext context, WidgetRef ref) {
    final vehicles = ref.read(vehiclesProvider).value ?? [];
    showModalBottomSheet(
      context: context, backgroundColor: Y.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Y.outlineStrong, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        ...vehicles.map((v) => ListTile(
          title: Text(v.name), subtitle: Text('${v.fuelGrade} 汽油', style: const TextStyle(color: Y.onSurface3)),
          onTap: () { setActiveVehicle(ref, v.id); Navigator.pop(c); },
        )),
        const SizedBox(height: 8),
      ])),
    );
  }
}
