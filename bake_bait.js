#!/usr/bin/env node
/* bake_bait.js — ベイト実データ焼き込み
 * 気象庁 日本沿岸域の海面水温（area135-138 TXT）＋ 茨城県 船曳漁況速報（シラスCPUE, 地区別）
 * を取得し、数値のみを抽出して同一オリジンの bait_live.json に書き出す。
 * 原資料の表・図・本文は転載しない（数値＝事実のみ）。出典は JSON と UI に明記。
 *
 * 使い方:
 *   node bake_bait.js                 # ネット取得して bait_live.json を更新
 *   node bake_bait.js --test <dir>    # ネット無し・<dir> の fixture でパーサ検証
 *
 * 出典: 気象庁 https://www.data.jma.go.jp/kaiyou/data/db/kaikyo/series/engan/engan.html
 *       茨城県 https://www.pref.ibaraki.jp/nourinsuisan/suishi/kaiyu/funabiki/funabiki-toppage.html
 */
'use strict';
const https = require('https');
const fs = require('fs');
const path = require('path');

const OUT = path.join(__dirname, 'bait_live.json');
const SST_AREAS = { '135': '宮城県沿岸', '136': '福島県沿岸', '137': '茨城県北部沿岸', '138': '茨城県南部沿岸' };
const SST_URL = a => `https://www.data.jma.go.jp/kaiyou/data/db/kaikyo/series/engan/txt/area${a}.txt`;
const FUNABIKI = 'https://www.pref.ibaraki.jp/nourinsuisan/suishi/kaiyu/funabiki/funabiki-toppage.html';
// 船曳漁況速報の地区（表の並び順）
const DISTRICTS = ['大津', '久慈町', '久慈浜丸小', '大洗町', '鹿島灘', 'はさき'];

function get(url, redir = 0) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'tsuriba-bake/1.0 (+github pages)' } }, r => {
      if ([301, 302, 303, 307, 308].includes(r.statusCode) && r.headers.location && redir < 5) {
        r.resume(); return get(new URL(r.headers.location, url).href, redir + 1).then(resolve, reject);
      }
      if (r.statusCode !== 200) { r.resume(); return reject(new Error(url + ' HTTP ' + r.statusCode)); }
      const d = []; r.on('data', c => d.push(c)); r.on('end', () => resolve(Buffer.concat(d).toString('utf8')));
    }).on('error', reject);
  });
}

// ---- 純粋パーサ（検証可能・ネット非依存）----
// SST TXT: "yyyy,mm,dd,areaNo,flag,Temp." の最終有効行を返す
function parseSST(txt) {
  const lines = txt.split(/\r?\n/);
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = lines[i].match(/^\s*(\d{4}),(\d{2}),(\d{2}),\s*(\d+),\s*([A-Za-z]),\s*(-?\d+(?:\.\d+)?)/);
    if (m) return { date: `${m[1]}-${m[2]}-${m[3]}`, flag: m[5], temp: parseFloat(m[6]) };
  }
  return null;
}

// 船曳漁況速報 HTML: 地区 → 最新（＝新しい日）の非「なし」CPUE を抽出
function parseFunabiki(html) {
  const out = {};
  // セルは同一行に連結、<tr>/見出しで改行。タグ除去後に走査。
  let s = html
    .replace(/<\/?(td|th)[^>]*>/gi, '  ')          // セル区切り（同一行）
    .replace(/<tr[\s>]/gi, '\n')                          // 行＝改行
    .replace(/<\/?(h1|h2|h3|caption)[^>]*>/gi, '\n')      // 見出し＝改行
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ');
  const lines = s.split('\n');
  let curDate = null;
  for (let raw of lines) {
    const line = raw.replace(/\s+/g, ' ').trim();
    if (!line) continue;
    const h = line.match(/令和(\d+)年(\d+)月(\d+)日/);      // 令和1=2019
    if (h) { curDate = `${2018 + (+h[1])}-${String(+h[2]).padStart(2, '0')}-${String(+h[3]).padStart(2, '0')}`; continue; }
    if (!curDate) continue;
    for (const dist of DISTRICTS) {
      if (out[dist]) continue;                 // 既に新しい日で採用済み
      const idx = line.indexOf(dist);
      if (idx < 0) continue;
      const after = line.slice(idx + dist.length);
      if (/^[\s]*なし/.test(after)) break; // その日は休漁 → この地区は次の（古い）日で探す
      const nums = (after.match(/-?\d[\d,]*\.?\d*/g) || []).map(x => parseFloat(x.replace(/,/g, '')));
      if (nums.length >= 3 && isFinite(nums[2])) out[dist] = { date: curDate, boats: nums[0], kg: nums[1], cpue: nums[2] };
      break;
    }
  }
  return out;
}

async function main() {
  const test = process.argv[2] === '--test';
  const fdir = process.argv[3] || '.';
  const sst = {}, cpue = {};
  for (const a of Object.keys(SST_AREAS)) {
    try {
      const txt = test ? fs.readFileSync(path.join(fdir, `area${a}.txt`), 'utf8') : await get(SST_URL(a));
      const p = parseSST(txt);
      if (p) sst[a] = { area: SST_AREAS[a], ...p };
    } catch (e) { console.error('SST', a, e.message); }
  }
  try {
    const html = test ? fs.readFileSync(path.join(fdir, 'funabiki.html'), 'utf8') : await get(FUNABIKI);
    Object.assign(cpue, parseFunabiki(html));
  } catch (e) { console.error('CPUE', e.message); }

  const json = {
    generated: new Date().toISOString(),
    sst, cpue,
    source: {
      sst: '気象庁 日本沿岸域の海面水温（沿岸海域, 速報値）',
      cpue: '茨城県水産試験場 船曳漁況速報（シラスCPUE, 地区別・数値のみ抽出／原表非転載）'
    }
  };
  fs.writeFileSync(OUT, JSON.stringify(json, null, 2));
  console.log('wrote', OUT);
  console.log(JSON.stringify(json, null, 2));
}

if (require.main === module) main();
module.exports = { parseSST, parseFunabiki };
