// Web-specific notification handler
document.addEventListener('DOMContentLoaded', function() {
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