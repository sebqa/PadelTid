console.log("Service worker script loaded - version 1");

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

//const messaging = firebase.messaging();

// Add this at the top of your service worker file
self.addEventListener('install', (event) => {
  console.log("Service worker installing...");
  // Force activation without waiting for page reload
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log("Service worker activating...");
  // Take control of all clients immediately
  event.waitUntil(clients.claim());
});

// Add this helper function for displaying notification source
function showDebugNotification(source) {
  self.registration.showNotification(`Debug: ${source}`, {
    body: `This notification came from ${source} at ${new Date().toISOString()}`,
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/notification_icon.png',
    tag: 'debug-notification'
  });
}

// This service worker should ONLY handle background messages
// We deliberately don't call showNotification for foreground messages

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


// Add this to your service worker file
self.addEventListener('push', (event) => {
  console.log('Push message received', event);
  
  // Ensure we show something even if the format is unexpected
  let title = 'PADELTID';
  let options = {
    body: 'You have a new notification',
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/logo.svg',
    vibrate: [200, 100, 200, 100, 400],
    data: {
      url: self.location.origin
    },
    tag: 'padeltid-' + Date.now()
  };
  
  // Try to parse the event data
  try {
    if (event.data) {
      const data = event.data.json();
      
      if (data.notification) {
        title = data.notification.title || title;
        options.body = data.notification.body || options.body;
      }
      
      if (data.data) {
        options.data = { ...options.data, ...data.data };
      }
    }
  } catch (e) {
    console.error('Error parsing push data', e);
  }
  
  // Show the notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});
