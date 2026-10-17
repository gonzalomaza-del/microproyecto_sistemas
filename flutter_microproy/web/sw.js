// Service worker del 15-Puzzle: guarda los archivos del juego para que
// funcione sin conexión. Flutter ya no trae uno que haga esto.
const CACHE = 'puzzle15-v1';

// Archivos principales que se guardan al instalar.
const CORE = [
  './',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/fonts/MaterialIcons-Regular.otf',
    'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'assets/fonts/fallback/Roboto-Regular.ttf',
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // Si algún archivo no existe en esta versión de Flutter, se ignora.
    await Promise.all(CORE.map((url) => cache.add(url).catch(() => {})));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Borra cachés de versiones anteriores.
    const keys = await caches.keys();
    await Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

// Responde desde la caché y actualiza en segundo plano (stale-while-revalidate).
self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || !request.url.startsWith('http')) return;

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(request, {
      ignoreSearch: request.mode === 'navigate',
    });

    const network = fetch(request)
      .then((response) => {
        if (response && (response.ok || response.type === 'opaque')) {
          cache.put(request, response.clone());
        }
        return response;
      })
      .catch(() => null);

    if (cached) return cached;

    const fresh = await network;
    if (fresh) return fresh;

    // Sin conexión y sin copia: para las páginas, devuelve la app guardada.
    if (request.mode === 'navigate') {
      const shell = await cache.match('index.html');
      if (shell) return shell;
    }
    return Response.error();
  })());
});