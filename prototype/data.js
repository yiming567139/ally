/* 油迹 · mock 数据 —— 演示满箱法计算（数字由满箱法真实反推，前后自洽）
 * 录入只填升数；油价为设置页维护的全局默认值，金额/成本全部由默认值折算 */
const VEHICLE = {
  name: '春风 450SR',       // 车型号
  fuelGrade: '95#',         // 所加油品（车辆仅维护这两项）
};

/* 设置页填写的常规油价默认值（元/L），全局唯一价格来源 */
const SETTINGS = { defaultPricePerL: 8.31 };

/* 加油记录（时间倒序展示，计算时按正序）
 * 满箱法：区间油耗 = (A, B] 段内加油量之和 / (B.odo − A.odo) × 100
 * 仅 isFull=true 的记录作为计算锚点；未加满记录参与累计但不出区间油耗 */
const FILLUPS = [
  { id: 12, date: '09-06', time: '18:42', odo: 6120, volume: 8.6, full: true },
  { id: 11, date: '08-28', time: '19:05', odo: 5812, volume: 5.0, full: false, note: '顺路补 50 块' },
  { id: 10, date: '08-24', time: '08:15', odo: 5680, volume: 9.4, full: true },
  { id:  9, date: '08-10', time: '17:58', odo: 5390, volume: 8.2, full: true },
  { id:  8, date: '07-29', time: '19:22', odo: 5120, volume: 3.0, full: false },
  { id:  7, date: '07-26', time: '09:41', odo: 5060, volume: 8.4, full: true },
  { id:  6, date: '07-12', time: '18:30', odo: 4800, volume: 9.1, full: true },
  { id:  5, date: '06-28', time: '20:10', odo: 4540, volume: 8.8, full: true },
  { id:  4, date: '06-14', time: '18:05', odo: 4290, volume: 8.6, full: true },
  { id:  3, date: '05-31', time: '19:47', odo: 4030, volume: 9.0, full: true },
  { id:  2, date: '05-18', time: '08:33', odo: 3780, volume: 9.2, full: true },
  { id:  1, date: '05-04', time: '17:20', odo: 3520, volume: 10.0, full: true, note: '提车首箱 · 基准' },
];

/* 满箱法计算：返回带区间油耗的段列表（新→旧） */
function computeSegments(records) {
  const asc = [...records].sort((a, b) => a.odo - b.odo);
  const segments = [];
  for (let i = 1; i < asc.length; i++) {
    const b = asc[i];
    if (!b.full) continue;
    // 向前找上一个加满锚点
    let j = i - 1;
    while (j >= 0 && !asc[j].full) j--;
    if (j < 0) continue;
    const a = asc[j];
    const dist = b.odo - a.odo;
    if (dist <= 0) continue;
    // (a, b] 段内油量：含 b，不含 a；金额按默认单价折算
    const fuel = asc.slice(j + 1, i + 1).reduce((s, r) => s + r.volume, 0);
    const cost = fuel * SETTINGS.defaultPricePerL;
    segments.push({
      from: a, to: b,
      dist, fuel, cost,
      l100: fuel / dist * 100,
      kmPerL: dist / fuel,
      costPerKm: cost / dist,
      hasPartial: asc.slice(j + 1, i).some(r => !r.full),   // 段内是否有中途补加
    });
  }
  return segments.reverse();
}

const SEGMENTS = computeSegments(FILLUPS);
const AVG_L100 = SEGMENTS.reduce((s, x) => s + x.fuel, 0) / SEGMENTS.reduce((s, x) => s + x.dist, 0) * 100;

/* 满箱续航统计（替代实时油量估算——App 平时拿不到里程，无实时余量可言）：
 * 仅统计「无中途补加」的满锚段，那些才是实打实的一箱油跑的距离 */
const PURE_SEGS = SEGMENTS.filter(s => !s.hasPartial);
const RANGE_AVG_KM = Math.round(PURE_SEGS.reduce((s, x) => s + x.dist, 0) / PURE_SEGS.length);
const RANGE_LAST_KM = PURE_SEGS[0].dist;   // 段列表为新→旧，第一个纯段即最近一箱

const fmt = (n, d = 2) => n.toFixed(d);
