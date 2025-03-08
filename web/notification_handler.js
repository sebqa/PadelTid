// Web-specific notification handler
document.addEventListener('DOMContentLoaded', function() {
  // Check for duplicate service workers first
  if ('serviceWorker' in navigator) {
    // List all service worker registrations
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
      console.log('Found', registrations.length, 'service worker registrations');
      
      // If we have more than one service worker with the same scope, unregister extras
      const uniqueScopes = {};
      registrations.forEach(reg => {
        if (uniqueScopes[reg.scope]) {
          console.log('Unregistering duplicate service worker for scope:', reg.scope);
          reg.unregister();
        } else {
          uniqueScopes[reg.scope] = reg;
        }
      });
    });
  }
  
  // Try to get notification permission immediately if possible
  if ('Notification' in window && Notification.permission !== 'granted' && Notification.permission !== 'denied') {
    // Some browsers require user gesture for notification permission
    document.addEventListener('click', function requestNotificationPermission() {
      Notification.requestPermission().then(function(permission) {
        if (permission === 'granted') {
          console.log('Notification permission granted!');
          
          // Test notification with system alert
          if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
            navigator.serviceWorker.controller.postMessage({
              type: 'NOTIFICATION_TEST',
              title: 'PADELTID',
              body: 'Notifications are now enabled!',
            });
          }
        }
      });
      
      // Remove listener after first click
      document.removeEventListener('click', requestNotificationPermission);
    });
  }
  
  // Add manual vibration support
  if ('vibrate' in navigator) {
    // Create a global function that can be called from Dart
    window.vibrate = function() {
      navigator.vibrate([200, 100, 200, 100, 400]);
      console.log('Manual vibration triggered');
    };
  }
});

// Add this to track notifications
let shownNotifications = {};

// Add a message listener for the service worker
navigator.serviceWorker.addEventListener('message', event => {
  if (event.data && event.data.type === 'CHECK_NOTIFICATION') {
    const notificationId = event.data.notificationId;
    
    // Check if we've already shown this notification
    if (shownNotifications[notificationId]) {
      console.log('Preventing duplicate notification:', notificationId);
      // Tell the service worker not to show it
      event.source.postMessage({
        type: 'NOTIFICATION_ALREADY_SHOWN',
        notificationId: notificationId
      });
    } else {
      // Mark this notification as shown
      shownNotifications[notificationId] = Date.now();
      
      // Clean up old notifications (keep for 30 mins)
      const thirtyMinutesAgo = Date.now() - (30 * 60 * 1000);
      Object.entries(shownNotifications).forEach(([id, timestamp]) => {
        if (timestamp < thirtyMinutesAgo) {
          delete shownNotifications[id];
        }
      });
    }
  }
}); 