/** app/javascript/pwa/register.js
 *  Enregistrement du Service Worker et gestion de l'install prompt
 */

// Enregistrement du Service Worker
export function registerServiceWorker() {
  if (!navigator.serviceWorker) {
    console.warn('Service Workers not supported');
    return;
  }

  navigator.serviceWorker
    .register('/service-worker.js', { scope: '/' })
    .then((registration) => {
      console.log('Service Worker registered:', registration.scope);

      // Écoute les mises à jour du SW
      registration.addEventListener('updatefound', () => {
        const newWorker = registration.installing;
        newWorker.addEventListener('statechange', () => {
          if (newWorker.state === 'activated') {
            // Nouvelle version disponible
            showUpdatePrompt(registration);
          }
        });
      });
    })
    .catch((err) => {
      console.error('Service Worker registration failed:', err);
    });
}

// Affiche une notification pour mettre à jour l'app
function showUpdatePrompt(registration) {
  const message = document.createElement('div');
  message.className = 'pwa-update-prompt';
  message.innerHTML = `
    <div class="pwa-update-content">
      <p>Une nouvelle version de Planexa est disponible !</p>
      <button class="pwa-update-btn-update">Mettre à jour</button>
      <button class="pwa-update-btn-dismiss">Plus tard</button>
    </div>
  `;

  document.body.appendChild(message);

  const updateBtn = message.querySelector('.pwa-update-btn-update');
  const dismissBtn = message.querySelector('.pwa-update-btn-dismiss');

  updateBtn.addEventListener('click', () => {
    registration.waiting.postMessage({ type: 'SKIP_WAITING' });
    message.remove();
    // Recharge la page après activation
    setTimeout(() => {
      window.location.reload();
    }, 1000);
  });

  dismissBtn.addEventListener('click', () => {
    message.remove();
  });
}

// Gestion du controllerchange (reload triggered by SW update)
navigator.serviceWorker.addEventListener('controllerchange', () => {
  // Page sera rechargée si SKIP_WAITING était triggered
});

// Install prompt — bannière "Ajouter à l'écran d'accueil"
let deferredPrompt = null;

export function setupInstallPrompt() {
  window.addEventListener('beforeinstallprompt', (e) => {
    // Prévient le prompt automatique du navigateur
    e.preventDefault();
    deferredPrompt = e;

    // Affiche notre prompt personnalisé
    showInstallPrompt();
  });

  window.addEventListener('appinstalled', () => {
    console.log('Planexa installed');
    deferredPrompt = null;
    // Envoyer un événement analytics
    if (window.gtag) {
      window.gtag('event', 'app_installed');
    }
  });
}

function showInstallPrompt() {
  const banner = document.createElement('div');
  banner.className = 'pwa-install-banner';
  banner.innerHTML = `
    <div class="pwa-install-content">
      <div class="pwa-install-icon">
        <img src="/icons/icon-192x192.png" alt="Planexa" />
      </div>
      <div class="pwa-install-text">
        <h3>Installer Planexa</h3>
        <p>Accédez à l'app directement depuis votre écran d'accueil</p>
      </div>
      <div class="pwa-install-actions">
        <button class="pwa-install-btn-install">Installer</button>
        <button class="pwa-install-btn-dismiss">Fermer</button>
      </div>
    </div>
  `;

  document.body.appendChild(banner);

  const installBtn = banner.querySelector('.pwa-install-btn-install');
  const dismissBtn = banner.querySelector('.pwa-install-btn-dismiss');

  installBtn.addEventListener('click', async () => {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      console.log(`User response to install prompt: ${outcome}`);
      deferredPrompt = null;
      banner.remove();
    }
  });

  dismissBtn.addEventListener('click', () => {
    banner.remove();
    // Ne pas re-montrer pendant 7 jours
    localStorage.setItem('pwa-install-dismiss', Date.now().toString());
  });

  // Vérifier si l'utilisateur a déjà rejeté le prompt récemment
  const lastDismiss = localStorage.getItem('pwa-install-dismiss');
  if (lastDismiss && Date.now() - parseInt(lastDismiss) < 7 * 24 * 60 * 60 * 1000) {
    banner.remove();
  }
}

// Détection qu'on est en mode PWA (app installée)
export function isRunningAsPWA() {
  return (
    window.matchMedia('(display-mode: standalone)').matches ||
    window.matchMedia('(display-mode: fullscreen)').matches ||
    window.matchMedia('(display-mode: minimal-ui)').matches ||
    navigator.standalone === true
  );
}

// Détection qu'on est offline
export function setupOfflineDetection() {
  window.addEventListener('online', () => {
    console.log('Back online');
    // Nettoyer les notifications offline
    const offlineBarrier = document.querySelector('.pwa-offline-indicator');
    if (offlineBarrier) {
      offlineBarrier.remove();
    }
  });

  window.addEventListener('offline', () => {
    console.log('You are offline');
    // Afficher une notification
    if (!document.querySelector('.pwa-offline-indicator')) {
      const indicator = document.createElement('div');
      indicator.className = 'pwa-offline-indicator';
      indicator.textContent = '⚠️ Vous êtes hors ligne. Les changements peuvent ne pas être synchronisés.';
      document.body.appendChild(indicator);
    }
  });
}

// Gérer le push des notifications
export function setupPushNotifications() {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    console.warn('Push notifications not supported');
    return;
  }

  // S'abonner aux notifications push
  navigator.serviceWorker.ready.then((registration) => {
    registration.pushManager
      .getSubscription()
      .then((subscription) => {
        if (subscription) {
          console.log('Already subscribed to push');
          return;
        }
        // S'abonner si pas déjà fait
        subscribeToPush(registration);
      });
  });

  // Listener pour les notifications push
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data.type === 'SHOW_NOTIFICATION') {
        const { title, options } = event.data;
        navigator.serviceWorker.ready.then((reg) => {
          reg.showNotification(title, options);
        });
      }
    });
  }
}

async function subscribeToPush(registration) {
  try {
    // Récupérer la clé publique VAPID du serveur
    const response = await fetch('/api/v1/push_subscriptions/vapid_key');
    const { vapidPublicKey } = await response.json();

    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
    });

    // Envoyer la souscription au serveur
    await fetch('/api/v1/push_subscriptions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        subscription: {
          endpoint: subscription.endpoint,
          auth: subscription.getKey('auth'),
          p256dh: subscription.getKey('p256dh')
        }
      })
    });

    console.log('Subscribed to push notifications');
  } catch (err) {
    console.error('Failed to subscribe to push:', err);
  }
}

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding)
    .replace(/\\-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; ++i) {
    outputArray[i] = rawData.charCodeAt(i);
  }
  return outputArray;
}

// Initialisation au chargement du DOM
export function initPWA() {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      registerServiceWorker();
      setupInstallPrompt();
      setupOfflineDetection();
      setupPushNotifications();
    });
  } else {
    registerServiceWorker();
    setupInstallPrompt();
    setupOfflineDetection();
    setupPushNotifications();
  }
}
