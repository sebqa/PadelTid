importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyAVwgqZ2E6LiUQB-zsniLA4EnUm781zs88",
    authDomain: "padeltid-85e2b.firebaseapp.com",
    projectId: "padeltid-85e2b",
    storageBucket: "padeltid-85e2b.appspot.com",
    messagingSenderId: "1569540045",
    appId: "1:1569540045:web:c06c7f452572a0948ca684",
    measurementId: "G-6SRZ7SK2BE"
});

const messaging = firebase.messaging();

// This service worker should ONLY handle background messages
// We deliberately don't call showNotification for foreground messages
messaging.onBackgroundMessage((message) => {
  console.log("SW: Background message received", message);
  
  // Don't display if this is a foreground message (handled by app)
  if (message.data && message.data.foreground === 'true') {
    console.log("SW: Skipping notification display for foreground message");
    return;
  }
  
  // Extract notification data from message
  const notificationTitle = message.notification.title || 'PADELTID';
  const notificationOptions = {
    body: message.notification.body || '',
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/logo.svg',
    vibrate: [200, 100, 200, 100, 200, 100, 400], // Stronger pattern
    silent: false, // Ensure sound plays
    renotify: true, // Force notification alert
    requireInteraction: true, // Make notification persist
    data: {
      url: self.location.origin,
    },
    tag: 'padeltid-notification-' + Date.now(), // Unique tag per notification
  };

  // Show the notification
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked', event);
  
  event.notification.close();
  
  // Open or focus the app
  const urlToOpen = event.notification.data?.url || self.location.origin;
  
  // Check if there's already a window/tab open with our app
  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    })
    .then((clientList) => {
      // Try to find an existing window
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      
      // If no window exists, open a new one
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
