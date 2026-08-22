import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const out = resolve(root, 'www');
const files = [
  'index.html',
  'manifest.webmanifest',
  'assets/category-icons.png',
  'assets/app-icon-180.png',
  'assets/app-icon-192.png',
  'assets/app-icon-512.png',
];

await rm(out, { recursive:true, force:true });
for (const file of files) {
  const target = resolve(out, file);
  await mkdir(dirname(target), { recursive:true });
  await cp(resolve(root, file), target);
}

const indexPath = resolve(out, 'index.html');
const html = await readFile(indexPath, 'utf8');
await writeFile(indexPath, html.replace('<body>', '<body data-native-shell="capacitor">'), 'utf8');
console.log(`Prepared Capacitor web assets in ${out}`);
