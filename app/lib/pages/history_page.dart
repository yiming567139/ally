import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/fuel_math.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import 'add_fillup_sheet.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fills = ref.watch(fillUpsProvider).value ?? const <FillUp>[];
    final price = ref.watch(defaultPriceProvider).value ?? 8.31;
    final segs = FuelMath.computeSegments(fills, price);
    final ecoById = {for (final s in segs) s.to.id: s};

    final totalL = fills.fold(0.0, (s, f) => s + f.volumeL);
    // 累计里程 = 最大里程 - 最小里程（不依赖排序，补录/同日多笔也不错算）
    double totalKm = 0;
    if (fills.length > 1) {
      final odos = fills.map((f) => f.odometer);
      totalKm = odos.reduce(math.max) - odos.reduce(math.min);
    }

    return Scaffold(
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('加油记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Y.surfaceHigh, border: Border.all(color: Y.outline), borderRadius: BorderRadius.circular(999)),
              child: Text('${fills.length} 笔', style: const TextStyle(fontSize: 12.5, color: Y.onSurface2)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _sum('${totalL.toStringAsFixed(1)}L', '累计加油'),
            _sum('¥${(totalL * price).round()}', '累计花费'),
            _sum(totalKm > 0 ? '${totalKm.round()}' : '—', '累计里程km'),
          ]),
          const SizedBox(height: 10),
          ..._groups(fills).entries.map((e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
              child: Row(children: [
                Text(e.key, style: const TextStyle(fontSize: 12, color: Y.onSurface2, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: Y.outline)),
              ]),
            ),
            ...e.value.map((r) => _item(context, ref, r, ecoById[r.id], price)),
          ])),
          if (fills.isEmpty) _empty(),
        ],
      )),
    );
  }

  Map<String, List<FillUp>> _groups(List<FillUp> fills) {
    final now = DateTime.now();
    String keyOf(DateTime d) => d.year == now.year ? '${d.month} 月' : '${d.year} 年 ${d.month} 月';
    final m = <String, List<FillUp>>{};
    for (final f in fills) {
      m.putIfAbsent(keyOf(f.filledAt), () => []).add(f);
    }
    return m;
  }

  Widget _sum(String v, String k) => Expanded(child: YCard(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Column(children: [
      Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
      const SizedBox(height: 4),
      Text(k, style: const TextStyle(fontSize: 10.5, color: Y.onSurface3)),
    ]),
  ));

  Widget _item(BuildContext context, WidgetRef ref, FillUp r, Segment? seg, double price) {
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Y.errorSoft, borderRadius: BorderRadius.circular(Y.rCard)),        child: const Icon(Icons.delete_outline, color: Y.error),
      ),
      confirmDismiss: (_) => yConfirm(context, title: '删除这条记录？', body: '${DateFormat('MM-dd HH:mm').format(r.filledAt)} · ${r.volumeL}L', danger: true),
      onDismissed: (_) async {
        final db = ref.read(dbProvider);
        await db.deleteFillUp(r.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('已删除'),
            action: SnackBarAction(label: '撤销', onPressed: () async {
              // 撤销=重新插入（id 自增即可，顺序由里程决定）
              await db.addFillUp(r.toCompanion(true));
            }),
          ));
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: YCard(
          color: r.isFullTank ? null : Y.surfaceHigh.withValues(alpha: .5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => showAddFillUpSheet(context, existing: r),
          child: Row(children: [
            SizedBox(width: 44, child: Column(children: [
              Text('${r.filledAt.day}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
              Text(DateFormat('HH:mm').format(r.filledAt), style: const TextStyle(fontSize: 10, color: Y.onSurface3)),
            ])),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r.isFullTank ? '加满' : '部分加油', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                _badge(r.isFullTank ? 'FULL' : 'PARTIAL', r.isFullTank ? Y.success : Y.primary),
              ]),
              const SizedBox(height: 3),
              Text('${r.volumeL}L · 表显 ${r.odometer.toStringAsFixed(0)} km${r.note != null ? ' · ${r.note}' : ''}',
                  style: const TextStyle(fontSize: 11.5, color: Y.onSurface3), overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(seg != null ? '${seg.l100.toStringAsFixed(2)}' : '—',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                      color: seg != null ? Y.success : Y.onSurface3, fontFeatures: const [FontFeature.tabularFigures()])),
              if (seg != null) const Text('L/100km', style: TextStyle(fontSize: 9.5, color: Y.onSurface3)),
              Text('¥${(r.volumeL * price).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11.5, color: Y.onSurface3)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
    decoration: BoxDecoration(border: Border.all(color: c.withValues(alpha: .38)), borderRadius: BorderRadius.circular(5)),
    child: Text(t, style: TextStyle(fontSize: 9.5, letterSpacing: 1.2, color: c)),
  );

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(children: [
      Icon(Icons.local_gas_station_outlined, size: 44, color: Y.onSurface3.withValues(alpha: .5)),
      const SizedBox(height: 14),
      const Text('还没有加油记录', style: TextStyle(color: Y.onSurface3)),
      const SizedBox(height: 6),
      const Text('点底部「＋」记第一笔', style: TextStyle(fontSize: 12, color: Y.onSurface3)),
    ]),
  );
}
