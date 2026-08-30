/* 釣り場マップ PWA service worker */
const CACHE = 'shiome-v43';
const SHELL = ['./','./index.html','./nationwide_ports.generated.js','./manifest.webmanifest','./tide_stations.json','./icon-192.png','./icon-512.png','./icon-512-maskable.png','./apple-touch-icon-180.png','./assets/fish-species-sprite-v1.png'];
self.addEventListener('install', (e) => { e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  const req = e.request; if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin === location.origin && url.pathname.startsWith('/api/')) {
    e.respondWith(fetch(req));
    return;
  }
  if (url.origin === location.origin && url.pathname.endsWith('bait_live.json')) {
    // 実データは毎日更新 → network-first（オフライン時のみキャッシュにフォールバック）
    e.respondWith(fetch(req).then((res) => { const c = res.clone(); caches.open(CACHE).then((x) => x.put(req, c)); return res; }).catch(() => caches.match(req)));
    return;
  }
  if (url.origin === location.origin && (req.mode === 'navigate' || url.pathname.endsWith('/') || url.pathname.endsWith('index.html'))) {
    // HTMLドキュメントは network-first（オンライン=常に最新を取得／オフライン時のみキャッシュ）＝「新版が反映されない」を根治。skipWaiting/clients.claimは維持。
    e.respondWith(fetch(req).then((res) => { const c = res.clone(); caches.open(CACHE).then((x) => x.put(req, c)); return res; }).catch(() => caches.match(req).then((h) => h || caches.match('./index.html'))));
    return;
  }
  if (url.origin === location.origin) {
    e.respondWith(caches.match(req).then((hit) => hit || fetch(req).then((res) => { const c = res.clone(); caches.open(CACHE).then((x) => x.put(req, c)); return res; }).catch(() => (req.mode === 'navigate' ? caches.match('./index.html') : undefined))));
    return;
  }
  e.respondWith(fetch(req).catch(() => caches.match(req)));
});
