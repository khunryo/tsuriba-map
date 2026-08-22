import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { extname, resolve } from 'node:path';

const root = resolve(import.meta.dirname);
const out = resolve(root, 'dist', 'server');
const files = [
  'index.html',
  'privacy.html',
  'manifest.webmanifest',
  'manifest-en.webmanifest',
  'sw.js',
  'assets/category-icons.png',
  'assets/app-icon-180.png',
  'assets/app-icon-192.png',
  'assets/app-icon-512.png',
];
const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.png': 'image/png',
};
const assets = {};

for (const file of files) {
  const bytes = await readFile(resolve(root, file));
  assets[`/${file}`] = {
    type: contentTypes[extname(file)],
    body: bytes.toString('base64'),
  };
}
assets['/'] = assets['/index.html'];

const worker = `const assets=${JSON.stringify(assets)};
function decode(value){const raw=atob(value);const bytes=new Uint8Array(raw.length);for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);return bytes;}
export default {async fetch(request){const url=new URL(request.url);let path=decodeURIComponent(url.pathname);if(path.endsWith('/'))path='/';const asset=assets[path]||(path.includes('.')?null:assets['/index.html']);if(!asset)return new Response('Not found',{status:404});const headers=new Headers({'content-type':asset.type,'cache-control':path==='/'||path==='/index.html'?'no-cache':'public, max-age=3600','x-content-type-options':'nosniff'});if(path==='/sw.js')headers.set('service-worker-allowed','/');return new Response(decode(asset.body),{status:200,headers});}};`;

await rm(resolve(root, 'dist'), { recursive: true, force: true });
await mkdir(out, { recursive: true });
await writeFile(resolve(out, 'index.js'), worker, 'utf8');
console.log(`Built ${resolve(out, 'index.js')}`);
