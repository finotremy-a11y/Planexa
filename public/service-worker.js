/** Service Worker — PlanifyPro PWA
 *  Stratégies de cache:
 *  - Cache-First: assets statiques (CSS, JS, images)
 *  - Network-First: pages dynamiques (dashboard, RDV)
 *  - Stale-While-Revalidate: pages publiques
 *  - Offline fallback: /offline.html
 */

const CACHE_VERSION = 'planify-pro-v1';
const STATIC_CACHE = `${CACHE_VERSION}:static`;
const DYNAMIC_CACHE = `${CACHE_VERSION}:dynamic`;
const OFFLINE_PAGE = '/offline.html';

// Assets statiques à précacher au premier chargement
const PRECACHE_ASSETS = [
  '/',
  OFFLINE_PAGE,
  '/assets/application.css',
  '/assets/application.js'
];

/** Installation du Service Worker — précache les assets statiques */
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS);
    }).then(() => {
      self.skipWaiting(); // Activate immediately
    })
  );
});

/** Activation du Service Worker — nettoie les vieux caches */
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => cacheName.startsWith('planify-pro-') && cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE)
          .map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => {
      self.clients.claim(); // Claim all clients
    })
  );
});

/** Fetch strategy — détermine cache vs network selon le type de requête */
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Ignorer les requêtes non-GET
  if (request.method !== 'GET') {
    return;
  }

  // Ignorer les requêtes vers des domaines externes
  if (url.origin !== location.origin) {
    return;
  }

  // Assets statiques — Cache-First
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // Pages publiques (login, about, etc) — Stale-While-Revalidate
  if (isPublicPage(url.pathname)) {
    event.respondWith(staleWhileRevalidate(request));
    return;
  }

  // Pages protégées (dashboard, RDV, etc) — Network-First
  event.respondWith(networkFirst(request));
});

/** Cache-First: cherche en cache, fallback réseau */
function cacheFirst(request) {
  return caches.match(request).then((cached) => {
    if (cached) {
      return cached;
    }
    return fetch(request).then((response) => {
      // Cache les réponses 200 (GET)
      if (!response || response.status !== 200 || response.type === 'error') {
        return response;
      }
      const responseToCache = response.clone();
      caches.open(STATIC_CACHE).then((cache) => {
        cache.put(request, responseToCache);
      });
      return response;
    }).catch(() => {
      return caches.match(OFFLINE_PAGE);
    });
  });
}

/** Network-First: cherche réseau d'abord, fallback cache */
function networkFirst(request) {
  return fetch(request)
    .then((response) => {
      // Cache les réponses valides
      if (!response || response.status !== 200) {
        return response;
      }
      const responseToCache = response.clone();
      caches.open(DYNAMIC_CACHE).then((cache) => {
        cache.put(request, responseToCache);
      });
      return response;
    })
    .catch(() => {
      return caches.match(request).then((cached) => {
        return cached || caches.match(OFFLINE_PAGE);
      });
    });
}

/** Stale-While-Revalidate: retourne le cache immédiatement, update en arrière-plan */
function staleWhileRevalidate(request) {
  return caches.match(request).then((cached) => {
    const fetchPromise = fetch(request).then((response) => {
      if (!response || response.status !== 200) {
        return response;
      }
      const responseToCache = response.clone();
      caches.open(DYNAMIC_CACHE).then((cache) => {
        cache.put(request, responseToCache);
      });
      return response;
    });

    return cached || fetchPromise;
  }).catch(() => {
    return caches.match(OFFLINE_PAGE);
  });
}

/** Détermine si l'URL est un asset statique (CSS, JS, images, fonts) */
function isStaticAsset(pathname) {
  return /\.(css|js|png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)$/.test(pathname) ||
         pathname.startsWith('/assets/') ||
         pathname.startsWith('/icons/');
}

/** Détermine si l'URL est une page publique */
function isPublicPage(pathname) {
  return pathname === '/' ||
         pathname.startsWith('/login') ||
         pathname.startsWith('/signup') ||
         pathname.startsWith('/about') ||
         pathname.startsWith('/terms') ||
         pathname.startsWith('/privacy') ||
         pathname.startsWith('/help');
}

/** Message handler — pour la communication entre app et SW */
self.addEventListener('message', (event) => {
  const { type, payload } = event.data;

  if (type === 'SKIP_WAITING') {
    self.skipWaiting();
  }

  if (type === 'CLEAR_CACHE') {
    caches.keys().then((cacheNames) => {
      cacheNames.forEach((cacheName) => {
        if (cacheName.startsWith('planify-pro-')) {
          caches.delete(cacheName);
        }
      });
    });
  }
});

/** Push notifications — écoute les push events */
self.addEventListener('push', (event) => {
  if (!event.data) {
    return;
  }

  let notificationData = {};
  try {
    notificationData = event.data.json();
  } catch {
    notificationData = {
      title: 'PlanifyPro',
      body: event.data.text()
    };
  }

  const { title, body, icon, badge, tag, data } = notificationData;

  const options = {
    body: body || '',
    icon: icon || '/icons/icon-192x192.png',
    badge: badge || '/icons/icon-192x192.png',
    tag: tag || 'planify-pro-notification',
    data: data || {},
    requireInteraction: false,
    actions: [
      {
        action: 'open',
        title: 'Ouvrir',
        icon: '/icons/icon-192x192.png'
      },
      {
        action: 'close',
        title: 'Fermer',
        icon: '/icons/icon-192x192.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification(title || 'PlanifyPro', options)
  );
});

/** Notification click handler */
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const { action, notification } = event;
  const { data } = notification;

  if (action === 'close') {
    return;
  }

  const urlToOpen = data.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Check if app is already open
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      // Open new window if not already open
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
