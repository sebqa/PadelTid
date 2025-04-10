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
  console.log('[SW] Notification clicked:', event);
  
  const notification = event.notification;
  notification.close();
  
  // Get the document ID from the notification data
  const documentId = notification.data && notification.data.documentId;
  const notificationId = notification.data && notification.data.notificationId;
  
  // Mark notification as clicked if we have an ID
  if (notificationId) {
    try {
      const dbPromise = indexedDB.open('padeltid_notifications_db', 1);
      dbPromise.onsuccess = function(event) {
        const db = event.target.result;
        const tx = db.transaction('notifications', 'readwrite');
        const store = tx.objectStore('notifications');
        
        const req = store.get(notificationId);
        req.onsuccess = function() {
          const notification = req.result;
          if (notification) {
            notification.clicked = true;
            notification.processed = true;
            store.put(notification);
          }
        };
        
        tx.oncomplete = function() {
          db.close();
        };
      };
    } catch (e) {
      console.error('[SW] Error marking notification as clicked:', e);
    }
  }
  
  // Handle navigation
  let url = '/';
  
  // Focus or open window
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true})
      .then(clientList => {
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if (client.url.includes(self.location.origin) && 'focus' in client) {
            client.focus();
            client.postMessage({
              type: 'NOTIFICATION_CLICKED',
              documentId: documentId,
              notificationId: notificationId
            });
            return;
          }
        }
        
        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      })
  );
});

// Add this helper function
function isIOSDevice() {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
}

// Add this to the top of your service worker
function debugLog(message, data) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    message: message,
    data: JSON.stringify(data || {}),
  };
  
  console.log(`[SW DEBUG] ${logEntry.timestamp}: ${message}`, data || '');
  
  // Also save to IndexedDB for persistent logging
  saveLogToIndexedDB(logEntry);
}

// Function to save logs to IndexedDB
function saveLogToIndexedDB(logEntry) {
  try {
    const dbPromise = indexedDB.open('padeltid_debug_logs', 1);
    
    dbPromise.onupgradeneeded = function(event) {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('logs')) {
        const store = db.createObjectStore('logs', { keyPath: 'id', autoIncrement: true });
        store.createIndex('timestamp', 'timestamp', { unique: false });
      }
    };
    
    dbPromise.onsuccess = function(event) {
      const db = event.target.result;
      const tx = db.transaction('logs', 'readwrite');
      const store = tx.objectStore('logs');
      
      store.add(logEntry);
      
      tx.oncomplete = function() {
        db.close();
      };
    };
  } catch (e) {
    console.error('Error saving log to IndexedDB:', e);
  }
}

// Add this to your service worker file
self.addEventListener('push', (event) => {
  debugLog('Push event received', event.data ? event.data.json() : null);
  
  // Default notification data
  let title = 'PADELTID';
  let body = 'You have a new notification';
  let documentId = null;
  
  try {
    if (event.data) {
      const data = event.data.json();
      console.log('[SW] Push data:', data);
      
      if (data.notification) {
        title = data.notification.title || title;
        body = data.notification.body || body;
      }
      
      if (data.data && data.data.documentId) {
        documentId = data.data.documentId;
      }
    }
  } catch (e) {
    console.error('[SW] Error parsing push data:', e);
  }
  
  // CRITICAL: Store this notification reliably with a unique ID
  const timestamp = Date.now();
  const notificationId = `notification_${timestamp}_${Math.random().toString(36).substr(2, 9)}`;
  
  // Create notification payload to store
  const notificationData = {
    id: notificationId,
    title: title, 
    body: body,
    documentId: documentId,
    timestamp: timestamp,
    processed: false
  };
  
  // STORE USING A DIRECT TECHNIQUE
  // Convert to URI-safe string and store in localStorage
  try {
    // Get existing notifications array
    let storedNotifications = [];
    try {
      const existingData = self.clients.matchAll().then(clients => {
        if (clients.length > 0) {
          clients[0].postMessage({
            type: 'STORE_BACKGROUND_NOTIFICATION',
            notificationData: notificationData
          });
          console.log('[SW] Sent notification directly to client');
        } else {
          console.log('[SW] No active clients, storing in db...');
          // Store in IndexedDB for retrieval later
          storeNotificationInIndexedDB(notificationData);
        }
      });
    } catch (e) {
      console.error('[SW] Error with client messaging:', e);
      storeNotificationInIndexedDB(notificationData);
    }
  } catch (e) {
    console.error('[SW] Error storing notification:', e);
  }
  
  // Prepare notification options
  const options = {
    body: body,
    icon: './assets/icon/logo.svg',
    badge: './assets/icon/badge-icon-96x96.png',
    data: {
      documentId: documentId,
      notificationId: notificationId,
      timestamp: timestamp
    },
    tag: 'padeltid-notification'
  };
  
  // Show the notification
  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

// IndexedDB storage helper function
function storeNotificationInIndexedDB(notification) {
  console.log('[SW] Storing notification in IndexedDB:', notification);
  
  try {
    const dbPromise = indexedDB.open('padeltid_notifications_db', 1);
    
    dbPromise.onupgradeneeded = function(event) {
      const db = event.target.result;
      if (!db.objectStoreNames.contains('notifications')) {
        const store = db.createObjectStore('notifications', { keyPath: 'id' });
        store.createIndex('processed', 'processed', { unique: false });
        store.createIndex('timestamp', 'timestamp', { unique: false });
      }
    };
    
    dbPromise.onsuccess = function(event) {
      const db = event.target.result;
      const tx = db.transaction('notifications', 'readwrite');
      const store = tx.objectStore('notifications');
      
      store.put(notification);
      
      tx.oncomplete = function() {
        console.log('[SW] Successfully stored notification in IndexedDB');
        db.close();
      };
    };
    
    dbPromise.onerror = function(event) {
      console.error('[SW] IndexedDB error:', event.target.error);
    };
  } catch (e) {
    console.error('[SW] Error in IndexedDB storage:', e);
  }
}

// Add this to your service worker to support synthetic test pushes
self.addEventListener('message', function(event) {
  if (event.data && event.data.type === 'DEBUG_TEST_PUSH') {
    debugLog('Received test push message', event.data);
    
    // Process this as if it were a real push
    const notificationData = {
      id: `test_${Date.now()}`,
      title: event.data.notification.title,
      body: event.data.notification.body,
      documentId: event.data.data.documentId,
      timestamp: event.data.data.timestamp,
      processed: false
    };
    
    // Store the notification
    storeNotificationInIndexedDB(notificationData);
    
    // Show the notification
    self.registration.showNotification(
      event.data.notification.title, 
      {
        body: event.data.notification.body,
        data: event.data.data
      }
    );
  }
});
