/* 油迹 · 原型动态注入：历史列表 + 图表（数据来自 data.js 的满箱法计算结果） */

/* ---------- 首页动态数值（与满箱法计算对齐，避免手写数字对不上） ---------- */
(() => {
  const $ = id => document.getElementById(id);
  if (!$('hero-value')) return;
  $('hero-value').textContent = fmt(AVG_L100);
  if ($('avg-line')) $('avg-line').textContent = fmt(AVG_L100);
  // 最新区间 vs 均值
  const last = SEGMENTS[0];
  const pct = (last.l100 - AVG_L100) / AVG_L100 * 100;
  $('hero-sub').textContent = (pct <= 0 ? '▾ ' : '▴ ') + '最新区间 ' + fmt(last.l100)
    + ' · ' + (pct <= 0 ? '低于' : '高于') + '均值 ' + Math.abs(pct).toFixed(0) + '%';
  // 本月（9月）实际油费 = 09-06 一笔
  const monthCost = FILLUPS.filter(r => r.date.startsWith('09')).reduce((s, r) => s + r.volume, 0) * SETTINGS.defaultPricePerL;
  $('month-cost').textContent = '¥' + fmt(monthCost, 1);
  $('cost-km').innerHTML = '¥' + fmt(last.costPerKm) + '<small>/km</small>';
  // 满箱续航卡：纯记录统计（无中途补加的段），不依赖任何实时数据
  $('range-avg').textContent = RANGE_AVG_KM;
  $('range-last').textContent = RANGE_LAST_KM;
  $('range-count').textContent = PURE_SEGS.length;
})();

/* ---------- P3 历史列表 ---------- */
(() => {
  const list = document.getElementById('history-list');
  if (!list) return;

  // 段索引：r.id → 区间油耗（作为 to 锚点的记录才有区间油耗）
  const ecoById = {};
  SEGMENTS.forEach(s => { ecoById[s.to.id] = s; });

  const groups = {};
  FILLUPS.forEach(r => {
    const mon = r.date.slice(0, 2);
    (groups[mon] = groups[mon] || []).push(r);
  });

  const monNames = { '05': '5 月', '06': '6 月', '07': '7 月', '08': '8 月', '09': '9 月' };
  let html = '';
  Object.keys(groups).sort((a, b) => b - a).forEach(mon => {
    html += `<div class="month-tag"><b>${monNames[mon]}</b><span class="num">${groups[mon].length} 笔</span></div>`;
    groups[mon].forEach(r => {
      const seg = ecoById[r.id];
      const isAnchor = r.full;
      html += `
      <div class="card fill-item ${r.full ? '' : 'partial'}">
        <div class="day"><div class="d num">${r.date.slice(3)}</div><div class="m">${mon}月 · ${r.time}</div></div>
        <div class="mid">
          <div class="title-line">${r.full ? '加满' : '部分加油'}${r.full ? '<span class="badge-partial badge-anchor">FULL</span>' : '<span class="badge-partial">PARTIAL</span>'}</div>
          <div class="meta num">${r.volume}L · 表显 ${r.odo} km${r.note ? ' · ' + r.note : ''}</div>
        </div>
        <div class="right">
          <div class="eco num">${seg ? fmt(seg.l100) + '<small> L/100km</small>' : '—'}</div>
          <div class="amt num">¥${fmt(r.volume * SETTINGS.defaultPricePerL)}</div>
        </div>
      </div>`;
    });
  });
  list.innerHTML = html;

  // 顶部汇总
  const totalL = FILLUPS.reduce((s, r) => s + r.volume, 0);
  const totalAmt = FILLUPS.reduce((s, r) => s + r.volume, 0) * SETTINGS.defaultPricePerL;
  document.getElementById('hs-total-l').textContent = fmt(totalL, 1) + 'L';
  document.getElementById('hs-total-amt').textContent = '¥' + Math.round(totalAmt);
})();

/* ---------- P4 油耗趋势折线（手绘 SVG） ---------- */
(() => {
  const box = document.getElementById('trend-chart');
  if (!box) return;
  const segs = [...SEGMENTS].reverse();           // 旧 → 新
  const W = 320, H = 150, PAD = 8;
  const vals = segs.map(s => s.l100);
  const min = Math.min(...vals) - .15, max = Math.max(...vals) + .15;
  const x = i => PAD + i * (W - PAD * 2) / (segs.length - 1);
  const y = v => H - PAD - (v - min) / (max - min) * (H - PAD * 2 - 12);

  const pts = vals.map((v, i) => `${x(i)},${y(v)}`).join(' ');
  const avgY = y(AVG_L100);

  let svg = `<svg viewBox="0 0 ${W} ${H}" style="width:100%;display:block">`;
  // 网格
  for (let g = 0; g < 3; g++) {
    const gy = PAD + g * (H - PAD * 2) / 2;
    svg += `<line x1="${PAD}" y1="${gy}" x2="${W - PAD}" y2="${gy}" stroke="rgba(148,163,184,.09)" stroke-width="1"/>`;
  }
  // 平均线
  svg += `<line x1="${PAD}" y1="${avgY}" x2="${W - PAD}" y2="${avgY}" stroke="rgba(148,163,184,.55)" stroke-width="1.2" stroke-dasharray="4 5"/>`;
  // 面积
  svg += `<polygon points="${PAD},${H - PAD} ${pts} ${W - PAD},${H - PAD}" fill="url(#tg)" opacity=".22"/>`;
  svg += `<defs><linearGradient id="tg" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#F59E0B"/><stop offset="1" stop-color="#F59E0B" stop-opacity="0"/></linearGradient></defs>`;
  // 折线
  svg += `<polyline points="${pts}" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/>`;
  // 数据点 + 最新值标签
  segs.forEach((s, i) => {
    const isLast = i === segs.length - 1;
    svg += `<circle cx="${x(i)}" cy="${y(vals[i])}" r="${isLast ? 4.5 : 3}" fill="#0B0F16" stroke="${isLast ? '#FCD34D' : '#F59E0B'}" stroke-width="2"/>`;
  });
  const li = segs.length - 1;
  svg += `<rect x="${x(li) - 26}" y="${y(vals[li]) - 26}" width="52" height="17" rx="8" fill="#F59E0B"/>
          <text x="${x(li)}" y="${y(vals[li]) - 14}" text-anchor="middle" font-size="10.5" font-weight="600" fill="#1A1207" font-family="Chakra Petch">${fmt(vals[li])}</text>`;
  // 首尾月份
  svg += `<text x="${PAD}" y="${H - 1}" font-size="8.5" fill="#6B7280" font-family="Chakra Petch">5月</text>`;
  svg += `<text x="${W - PAD}" y="${H - 1}" text-anchor="end" font-size="8.5" fill="#6B7280" font-family="Chakra Petch">9月</text>`;
  svg += '</svg>';
  box.innerHTML = svg;
})();

/* ---------- P4 月度油费柱状 ---------- */
(() => {
  const box = document.getElementById('month-chart');
  if (!box) return;
  const byMonth = {};
  FILLUPS.forEach(r => {
    const m = r.date.slice(0, 2);
    byMonth[m] = (byMonth[m] || 0) + r.volume * SETTINGS.defaultPricePerL;
  });
  const max = Math.max(...Object.values(byMonth));
  box.innerHTML = Object.keys(byMonth).sort().map(m => `
    <div class="bar-row">
      <span class="bl num">${+m} 月</span>
      <div class="track"><i style="width:${Math.round(byMonth[m] / max * 100)}%"></i></div>
      <span class="bv num">¥${Math.round(byMonth[m])}</span>
    </div>`).join('');
})();

/* ---------- P4 单价走势：已按需求移除（油价为全局默认值，单价恒为常数，无走势可言） ---------- */

/* ---------- 站点对比功能已整体移除 ---------- */
