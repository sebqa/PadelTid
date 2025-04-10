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

// Add this helper function
function isIOSDevice() {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
}

// Add this to your service worker file
self.addEventListener('push', (event) => {
  console.log('Push message received', event);
  
  let title = 'PADELTID';
  let options = {
    body: 'You have a new notification',
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/badge-icon-96x96.png',
    vibrate: [200, 100, 200, 100, 400],
    data: {
      url: self.location.origin,
      documentId: null,
      timestamp: Date.now()
    },
    tag: 'padeltid-' + Date.now()
  };
  
  // Parse data from the push event
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
      
      // Create notification data object to store
      const notificationData = {
        title: title,
        body: options.body,
        documentId: options.data.documentId,
        timestamp: Date.now()
      };
      
      // iOS may have issues with complex IndexedDB operations
      if (isIOSDevice()) {
        // For iOS, make the stored notification simpler
        notificationData.platformInfo = 'ios'; // Mark it came from iOS
        console.log('Optimized notification storage for iOS');
      }
      
      // First try to send to any active clients
      const clientsPromise = self.clients.matchAll({type: 'window'})
        .then(clients => {
          if (clients.length > 0) {
            // App is running, send to client
            clients[0].postMessage({
              type: 'NOTIFICATION_RECEIVED_BACKGROUND',
              notificationData: notificationData
            });
            return true; // Notification sent to client
          }
          return false; // No clients available
        });
      
      // Then save to IndexedDB if needed
      event.waitUntil(
        clientsPromise.then(sentToClient => {
          if (!sentToClient) {
            // No clients active, store in IndexedDB
            return saveBackgroundNotification(notificationData);
          }
        })
      );
    }
  } catch (e) {
    console.error('Error processing push data:', e);
  }
  
  // Show the notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Save notification to IndexedDB for background storage
function saveBackgroundNotification(notification) {
  return new Promise((resolve, reject) => {
    const DB_NAME = 'background_notifications_db';
    const STORE_NAME = 'notifications';
    const dbRequest = indexedDB.open(DB_NAME, 1);
    
    dbRequest.onupgradeneeded = function(event) {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id', autoIncrement: true });
      }
    };
    
    dbRequest.onerror = function(event) {
      console.error('Error opening IndexedDB:', event.target.error);
      reject(event.target.error);
    };
    
    dbRequest.onsuccess = function(event) {
      try {
        const db = event.target.result;
        const transaction = db.transaction([STORE_NAME], 'readwrite');
        const store = transaction.objectStore(STORE_NAME);
        
        // Add notification to store
        const request = store.add(notification);
        
        request.onsuccess = function() {
          console.log('Successfully stored background notification in IndexedDB');
          resolve();
        };
        
        request.onerror = function(event) {
          console.error('Error storing notification:', event.target.error);
          reject(event.target.error);
        };
        
        transaction.oncomplete = function() {
          db.close();
        };
      } catch (e) {
        console.error('Error in IndexedDB transaction:', e);
        reject(e);
      }
    };
  });
}
