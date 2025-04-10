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
      timestamp: Date.now()
    },
    tag: 'padeltid-' + Date.now()
  };
  
  let notificationData = {};
  
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
      
      // Save notification data for later processing
      notificationData = {
        title: title,
        body: options.body,
        documentId: options.data.documentId,
        messageId: data.messageId || null
      };
      
      // Save to IndexedDB for later processing
      event.waitUntil(saveNotification(notificationData));
    }
  } catch (e) {
    console.error('Error parsing push data', e);
  }
  
  // Show the notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// Add this near the top of your service worker file
const DB_NAME = 'notifications_db';
const STORE_NAME = 'background_notifications';

// Initialize the IndexedDB
function openDatabase() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    
    request.onerror = (event) => {
      console.error('Error opening IndexedDB:', event.target.error);
      reject(event.target.error);
    };
    
    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id' });
      }
    };
    
    request.onsuccess = (event) => {
      resolve(event.target.result);
    };
  });
}

// Save notification to IndexedDB
async function saveNotification(notification) {
  try {
    const db = await openDatabase();
    const tx = db.transaction(STORE_NAME, 'readwrite');
    const store = tx.objectStore(STORE_NAME);
    
    // Add timestamp and unique ID
    notification.id = `bg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    notification.timestamp = Date.now();
    notification.processed = false;
    
    store.add(notification);
    
    return new Promise((resolve, reject) => {
      tx.oncomplete = () => {
        console.log('Notification saved to IndexedDB:', notification);
        resolve();
      };
      
      tx.onerror = (event) => {
        console.error('Error saving notification:', event.target.error);
        reject(event.target.error);
      };
    });
  } catch (error) {
    console.error('Failed to save notification:', error);
  }
}
