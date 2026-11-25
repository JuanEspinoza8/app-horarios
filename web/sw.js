'use strict';
// Service worker de la versión web: después de abrirla una vez, la app funciona
// sin conexión (Flutter 3.44 ya no genera uno que haga esto).
//
// Estrategia "stale-while-revalidate": responde al instante con la copia
// guardada y la actualiza en segundo plano. Una versión nueva publicada se ve
// en la apertura siguiente.

const CACHE = 'horas-extras-v1';

// Lo mínimo para abrir y exportar sin conexión aunque no se haya usado antes
// (p. ej. la plantilla Word solo se pide al exportar). El resto (motor gráfico,
// fuentes) se guarda la primera vez que se pide.
const PRECACHE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/apple-touch-icon.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/assets/plantilla.docx',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      await Promise.all(PRECACHE.map((url) => cache.add(url).catch(() => {})));
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      for (const key of await caches.keys()) {
        if (key !== CACHE) await caches.delete(key);
      }
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  const mismoOrigen = url.origin === self.location.origin;
  // Fuentes que el motor de Flutter pide a Google la primera vez.
  const fuentes = url.hostname === 'fonts.gstatic.com';
  if (!mismoOrigen && !fuentes) return;
  if (url.pathname.endsWith('/sw.js') || url.pathname.endsWith('flutter_service_worker.js')) return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE);
      const guardado = await cache.match(req);
      const red = fetch(req)
        .then((res) => {
          if (res && (res.ok || res.type === 'opaque')) cache.put(req, res.clone());
          return res;
        })
        .catch(() => undefined);

      if (guardado) {
        event.waitUntil(red);
        return guardado;
      }
      const res = await red;
      if (res) return res;
      if (req.mode === 'navigate') {
        const inicio = await cache.match('./');
        if (inicio) return inicio;
      }
      return Response.error();
    })(),
  );
});
