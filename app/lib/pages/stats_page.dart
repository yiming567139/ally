import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/fuel_math.dart';
import '../data/providers.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  int _months = 6; // 3 / 6 / 0(全部)

  @override
  Widget build(BuildContext context) {
    final fills = ref.watch(fillUpsProvider).value ?? const <FillUp>[];
    final price = ref.watch(defaultPriceProvider).value ?? 8.31;
    var segs = FuelMath.computeSegments(fills, price);
    if (_months > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: _months * 31));
      segs = segs.where((s) => s.to.filledAt.isAfter(cutoff)).toList();
    }
    final avg = FuelMath.avgL100(segs);

    return Scaffold(
      body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 110), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          _rangeSeg(),
        ]),
        const SizedBox(height: 16),

        // 区间油耗趋势
        YCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('区间油耗趋势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(avg > 0 ? '均值 ${avg.toStringAsFixed(2)} L/100km' : '暂无数据',
                style: const TextStyle(fontSize: 11, color: Y.onSurface3, fontFeatures: [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: segs.length < 2
              ? const Center(child: Text('至少两笔加满后出趋势', style: TextStyle(color: Y.onSurface3, fontSize: 12)))
              : LineChart(_trendChart(segs.reversed.toList(), avg))),
          const SizedBox(height: 8),
          const Row(children: [
            _Legend(color: Y.primary, label: '区间油耗'),
            SizedBox(width: 16),
            _Legend(color: Y.onSurface3, label: '平均线', dashed: true),
          ]),
        ])),
        const SizedBox(height: 14),

        // 月度油费
        YCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('月度油费', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('按默认油价 ${price.toStringAsFixed(2)} 元/L 折算',
                style: const TextStyle(fontSize: 11, color: Y.onSurface3, fontFeatures: [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 16),
          SizedBox(height: 140, child: fills.isEmpty
              ? const Center(child: Text('暂无记录', style: TextStyle(color: Y.onSurface3, fontSize: 12)))
              : BarChart(_monthChart(fills, price))),
        ])),
      ])),
    );
  }

  Widget _rangeSeg() {
    return Container(
      decoration: BoxDecoration(color: Y.surfaceContainer, border: Border.all(color: Y.outline), borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(2),
      child: Row(children: [
        for (final (label, v) in [('3月', 3), ('半年', 6), ('全部', 0)])
          GestureDetector(
            onTap: () => setState(() => _months = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _months == v ? Y.surfaceHigh : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: _months == v ? Border.all(color: Y.outlineStrong) : null,
              ),
              child: Text(label, style: TextStyle(fontSize: 11, color: _months == v ? Y.onSurface : Y.onSurface3)),
            ),
          ),
      ]),
    );
  }

  LineChartData _trendChart(List<Segment> segs, double avg) {
    final spots = [for (var i = 0; i < segs.length; i++) FlSpot(i.toDouble(), segs[i].l100)];
    final minY = segs.map((s) => s.l100).reduce((a, b) => a < b ? a : b) - .3;
    final maxY = segs.map((s) => s.l100).reduce((a, b) => a > b ? a : b) + .3;
    return LineChartData(
      minY: minY, maxY: maxY,
      gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0x1794A3B8), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(), topTitles: const AxisTitles(),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: Y.onSurface3)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 18,
            getTitlesWidget: (v, _) {
              final i = v.round();
              if (i < 0 || i >= segs.length) return const SizedBox();
              return Text('${segs[i].to.filledAt.month}月', style: const TextStyle(fontSize: 8.5, color: Y.onSurface3));
            })),
      ),
      extraLinesData: avg > 0 ? ExtraLinesData(horizontalLines: [
        HorizontalLine(y: avg, color: Y.onSurface3.withOpacity(.55), strokeWidth: 1.2, dashArray: [4, 5]),
      ]) : const ExtraLinesData(),
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Y.surfaceHigh,
        getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
          '${segs[s.x.toInt()].to.filledAt.month}-${segs[s.x.toInt()].to.filledAt.day}\n${s.y.toStringAsFixed(2)} L/100km · ${segs[s.x.toInt()].dist.round()} km',
          const TextStyle(color: Y.onSurface, fontSize: 11),
        )).toList(),
      )),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: false,
        color: Y.primary, barWidth: 2.2,
        dotData: FlDotData(show: true, getDotPainter: (_, __, ___, i) =>
            FlDotCirclePainter(radius: i == segs.length - 1 ? 4.5 : 3, color: Y.surface, strokeColor: Y.primary, strokeWidth: 2)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Y.primary.withOpacity(.22), Y.primary.withOpacity(0)])),
      )],
    );
  }

  BarChartData _monthChart(List<FillUp> fills, double price) {
    final byMonth = <int, double>{};
    for (final f in fills) {
      byMonth[f.filledAt.month] = (byMonth[f.filledAt.month] ?? 0) + f.volumeL * price;
    }
    final keys = byMonth.keys.toList()..sort();
    final maxV = byMonth.values.fold(0.0, (a, b) => a > b ? a : b);
    return BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(), rightTitles: const AxisTitles(), topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) => Text('${keys[v.toInt()]}月', style: const TextStyle(fontSize: 10, color: Y.onSurface3)))),
      ),
      barGroups: [for (var i = 0; i < keys.length; i++)
        BarChartGroupData(x: i, barRods: [BarChartRodData(
          toY: byMonth[keys[i]]!, width: 22,
          gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Color(0xFF92400E), Y.primary]),
          borderRadius: BorderRadius.circular(6),
        )]),
      ],
      maxY: maxV * 1.15,
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color; final String label; final bool dashed;
  const _Legend({required this.color, required this.label, this.dashed = false});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 14, height: 2, color: color),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 10.5, color: Y.onSurface3)),
  ]);
}
