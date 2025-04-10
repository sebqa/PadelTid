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
    badge: './assets/icon/badge-icon-96x96.png',
    tag: 'debug-notification'
  });
}

// This service worker should ONLY handle background messages
// We deliberately don't call showNotification for foreground messages

// Handle notification clicks more gracefully
self.addEventListener('notificationclick', function(event) {
  console.log('Notification clicked:', event);
  
  try {
    const notification = event.notification;
    notification.close();
    
    // Get the document ID from the notification data
    const documentId = notification.data && notification.data.documentId;
    
    // Create a URL to navigate to
    let url = '/';
    
    // Focus on existing tab if available, otherwise open new one
    event.waitUntil(
      clients.matchAll({type: 'window', includeUncontrolled: true})
        .then(function(clientList) {
          for (let i = 0; i < clientList.length; i++) {
            const client = clientList[i];
            if ('focus' in client) {
              client.focus();
              client.navigate(url);
              return;
            }
          }
          
          // No existing window/tab, open a new one
          if (clients.openWindow) {
            return clients.openWindow(url);
          }
        })
        .catch(function(error) {
          console.error('Error handling notification click:', error);
        })
    );
  } catch (error) { 
    console.error('Error in notification click handler:', error);
  }
});


// Add this to your service worker file
self.addEventListener('push', (event) => {
  console.log('Push message received', event);
  
  // Ensure we show something even if the format is unexpected
  let title = 'PADELTID';
  let options = {
    body: 'You have a new notification',
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/badge-icon-96x96.png',
    vibrate: [200, 100, 200, 100, 400],
    data: {
      url: self.location.origin,
      documentId: null,
      documentData: null,
      timestamp: Date.now()
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
      
      // Store document data from the notification payload
      if (data.data) {
        options.data = { ...options.data, ...data.data };
      }
      
      // Try to send the notification data to all clients to store in history
      self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true
      }).then(clients => {
        if (clients && clients.length) {
          // Send to first client
          clients[0].postMessage({
            type: 'NOTIFICATION_RECEIVED',
            title: title,
            body: options.body,
            documentId: options.data.documentId,
            timestamp: options.data.timestamp || Date.now()
          });
        }
      });
    }
  } catch (e) {
    console.error('Error parsing push data', e);
  }
  
  // Show the notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});
