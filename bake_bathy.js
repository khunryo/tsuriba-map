#!/usr/bin/env node
/* bake_bathy.js — 海底断面(沖側)の実測水深を焼き込む（静的・一度きり/年1でOK）
 * 各釣り場の沖方位(offBearing)に沿って GEBCO（GEBCO_2020, 全球15秒, 無償・出典表示）を
 * 数点サンプルし bathy.json を生成。公開アプリはGEBCOを直接叩かず、この自作JSONを読む。
 * 取得は OpenTopoData 公開API（GEBCO_2020ラッパ, オープンソース）。原グリッド直取得でも可。
 * 釣りどこ/アジア航測ALB/M7000等の有償・限定データは一切不使用。
 *
 * 使い方: node bake_bathy.js            # index.html から地点を読み、bathy.json を生成
 * 出典表記: GEBCO Compilation Group (GEBCO_2020 Grid)
 */
'use strict';
const https = require('https');
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, 'bathy.json');
const SRC = path.join(__dirname, 'index.html');
const DIST = [300, 1000, 2000, 4000, 8000]; // m offshore
const API = 'https://api.opentopodata.org/v1/gebco2020';
const SLEEP = ms => new Promise(r => setTimeout(r, ms));

function get(url) {
  return new Promise((res, rej) => {
    https.get(url, { headers: { 'User-Agent': 'tsuriba-bathy/1.0' } }, r => {
      if (r.statusCode !== 200) { r.resume(); return rej(new Error('HTTP ' + r.statusCode)); }
      const d = []; r.on('data', c => d.push(c)); r.on('end', () => res(Buffer.concat(d).toString('utf8')));
    }).on('error', rej);
  });
}

// index.html から SHORE_ANCHOR { name:{lat,lon,b} } を抽出
function readSpots(html) {
  const blk = html.match(/const SHORE_ANCHOR=\{([\s\S]*?)\n\};/)[1];
  const re = /['"]([^'"]+)['"]\s*:\s*\{lat:([-\d.]+),lon:([-\d.]+),b:([-\d.]+)/g;
  const out = []; let m;
  while ((m = re.exec(blk))) out.push({ name: m[1], lat: +m[2], lon: +m[3], b: +m[4] });
  return out;
}

function samplePoints(sp) {
  const th = sp.b * Math.PI / 180;
  return DIST.map(d => [
    +(sp.lat + d * Math.cos(th) / 111320).toFixed(5),
    +(sp.lon + d * Math.sin(th) / (111320 * Math.cos(sp.lat * Math.PI / 180))).toFixed(5)
  ]);
}

async function main() {
  const html = fs.readFileSync(SRC, 'utf8');
  const spots = readSpots(html);
  console.log('spots:', spots.length);
  // 全点をまとめて（OpenTopoDataは100点/リクエスト）
  const all = []; const map = [];
  for (const sp of spots) samplePoints(sp).forEach((p, i) => { all.push(p); map.push([sp.name, i]); });
  const depth = {};
  for (let i = 0; i < all.length; i += 100) {
    const chunk = all.slice(i, i + 100);
    const loc = chunk.map(p => p[0] + ',' + p[1]).join('|');
    const j = JSON.parse(await get(API + '?locations=' + encodeURIComponent(loc)));
    j.results.forEach((r, k) => {
      const [name, di] = map[i + k];
      (depth[name] = depth[name] || [])[di] = (r.elevation != null && r.elevation < 0) ? Math.round(-r.elevation) : 0;
    });
    await SLEEP(1200); // 公開APIへの礼儀（レート制限回避）
    console.log('fetched', Math.min(i + 100, all.length), '/', all.length);
  }
  const json = { generated: new Date().toISOString().slice(0, 10),
    source: 'GEBCO Compilation Group (GEBCO_2020 Grid)',
    note: '沖側水深(m,正値)=GEBCO実測。近岸0〜' + DIST[0] + 'mは自作モデル(Dean)で補完。',
    dist_m: DIST, depth };
  fs.writeFileSync(OUT, JSON.stringify(json, null, 2));
  console.log('wrote', OUT, '| spots with depth:', Object.keys(depth).length);
}
if (require.main === module) main();
module.exports = { readSpots, samplePoints };
