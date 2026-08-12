import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const year = process.argv[2] || String(new Date().getFullYear());
const stations = JSON.parse(await readFile(new URL('../tide_stations.json', import.meta.url), 'utf8'));
const output = new URL('../tide_data/', import.meta.url);
await mkdir(output, { recursive: true });

let cursor = 0;
let completed = 0;
const tables = {};
const workers = Array.from({ length: 12 }, async () => {
  while (cursor < stations.length) {
    const station = stations[cursor++];
    const url = `https://www.data.jma.go.jp/kaiyou/data/db/tide/suisan/txt/${year}/${station.code}.txt`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${station.code}: HTTP ${response.status}`);
    tables[station.code] = await response.text();
    completed += 1;
  }
});

await Promise.all(workers);
await writeFile(new URL(`${year}.json`, output), JSON.stringify(tables));
console.log(`Downloaded ${completed} JMA tide tables for ${year} to ${path.resolve(new URL(output).pathname)}`);
