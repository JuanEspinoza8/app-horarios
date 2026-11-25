{{flutter_js}}
{{flutter_build_config}}

// Se carga sin "serviceWorkerSettings": el service worker de Flutter 3.44 solo se
// desregistra. El propio (sw.js, para usar la app sin conexión) lo registra index.html.
_flutter.loader.load();
