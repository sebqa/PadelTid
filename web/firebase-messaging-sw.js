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

// Add notification options for background messages
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
  
  // Extract notification data from message
  const notificationTitle = message.notification.title || 'PADELTID';
  const notificationOptions = {
    body: message.notification.body || '',
    icon: '/assets/icon/logo.svg',  // This path must be accessible in PWA context
    badge: '/assets/icon/logo.svg', // This path must be accessible in PWA context
    vibrate: [200, 100, 200], // Vibration pattern
    data: {
      url: self.location.origin // URL to open when clicked
    },
    actions: [
      {
        action: 'open',
        title: 'Open App'
      }
    ]
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
        if (client.url === urlToOpen && 'focus' in client) {
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
