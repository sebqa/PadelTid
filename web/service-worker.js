// Add a proper caching strategy to your service worker

// Cache API responses
self.addEventListener('fetch', (event) => {
  // Only cache API calls
  if (event.request.url.includes('execute-api.eu-north-1.amazonaws.com')) {
    event.respondWith(
      caches.open('api-cache').then((cache) => {
        return fetch(event.request).then((response) => {
          // Clone the response to store in cache and return the original
          cache.put(event.request, response.clone());
          return response;
        }).catch(() => {
          // If network request fails, try to return from cache
          return cache.match(event.request);
        });
      })
    );
  }
});

// Precache essential assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('static-assets').then((cache) => {
      return cache.addAll([
        '/',
        '/index.html',
        '/flutter.js',
        '/flutter_bootstrap.js',
        '/assets/icon/logo.svg',
        '/assets/icon/maskable_logo.svg',
        '/manifest.json'
      ]);
    })
  );
}); 