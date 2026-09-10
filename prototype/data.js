/* 油迹 · mock 数据 —— 演示满箱法计算 */
const VEHICLE = {
  name: '春风 450SR',
  tankCapacity: 14,          // L
  fuelGrade: '95#',
  displacement: '450cc',
};

/* 加油记录（时间倒序展示，计算时按正序）
 * 满箱法：区间油耗 = (A, B] 段内加油量之和 / (B.odo − A.odo) × 100
 * 仅 isFull=true 的记录作为计算锚点；未加满记录参与累计但不出区间油耗 */
const FILLUPS = [
  { id: 12, date: '09-06', time: '18:42', odo: 6120, volume: 11.2, price: 8.31, amount: 93.07, full: true,  station: '中石化 · 学府路' },
  { id: 11, date: '08-28', time: '19:05', odo: 5812, volume: 5.0,  price: 8.31, amount: 41.55, full: false, station: '中石油 · 三环辅路', note: '顺路补 50 块' },
  { id: 10, date: '08-24', time: '08:15', odo: 5680, volume: 9.8,  price: 8.31, amount: 81.44, full: true,  station: '中石化 · 学府路' },
  { id:  9, date: '08-10', time: '17:58', odo: 5390, volume: 10.1, price: 8.45, amount: 85.35, full: true,  station: '壳牌 · 机场高速' },
  { id:  8, date: '07-29', time: '19:22', odo: 5120, volume: 3.0,  price: 8.45, amount: 25.35, full: false, station: '中石化 · 学府路' },
  { id:  7, date: '07-26', time: '09:41', odo: 5060, volume: 9.5,  price: 8.45, amount: 80.28, full: true,  station: '中石油 · 开发区' },
  { id:  6, date: '07-12', time: '18:30', odo: 4800, volume: 9.9,  price: 8.52, amount: 84.35, full: true,  station: '中石化 · 学府路' },
  { id:  5, date: '06-28', time: '20:10', odo: 4540, volume: 9.6,  price: 8.52, amount: 81.79, full: true,  station: '中石化 · 学府路' },
  { id:  4, date: '06-14', time: '18:05', odo: 4290, volume: 9.4,  price: 8.66, amount: 81.40, full: true,  station: '壳牌 · 机场高速' },
  { id:  3, date: '05-31', time: '19:47', odo: 4030, volume: 9.8,  price: 8.66, amount: 84.87, full: true,  station: '中石油 · 开发区' },
  { id:  2, date: '05-18', time: '08:33', odo: 3780, volume: 9.2,  price: 8.73, amount: 80.32, full: true,  station: '中石化 · 学府路' },
  { id:  1, date: '05-04', time: '17:20', odo: 3520, volume: 10.0, price: 8.73, amount: 87.30, full: true,  station: '中石化 · 学府路', note: '提车首箱 · 基准' },
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
    // (a, b] 段内油量：含 b，不含 a
    const fuel = asc.slice(j + 1, i + 1).reduce((s, r) => s + r.volume, 0);
    const cost = asc.slice(j + 1, i + 1).reduce((s, r) => s + r.amount, 0);
    segments.push({
      from: a, to: b,
      dist, fuel, cost,
      l100: fuel / dist * 100,
      kmPerL: dist / fuel,
      costPerKm: cost / dist,
    });
  }
  return segments.reverse();
}

const SEGMENTS = computeSegments(FILLUPS);
const AVG_L100 = SEGMENTS.reduce((s, x) => s + x.fuel, 0) / SEGMENTS.reduce((s, x) => s + x.dist, 0) * 100;
const LAST_ANCHOR = [...FILLUPS].sort((a, b) => b.odo - a.odo).find(r => r.full);
const CURRENT_ODO = 6186;                    // 当前里程（假设）
const TANK_USED = CURRENT_ODO - LAST_ANCHOR.odo;   // 本箱已跑
const TANK_REMAIN_L = Math.max(VEHICLE.tankCapacity - TANK_USED / 100 * AVG_L100, 0);
const RANGE_KM = Math.round(TANK_REMAIN_L / AVG_L100 * 100);

const fmt = (n, d = 2) => n.toFixed(d);
