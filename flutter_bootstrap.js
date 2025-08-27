// Optimized Flutter loading
window.addEventListener('load', function() {
  // Check if serviceWorkerVersion is defined, use null if not
  const serviceWorkerVersion = self.serviceWorkerVersion || null;
  
  // Request notification and vibration permissions for PWA
  if ('Notification' in window) {
    if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
      // Only ask if not already granted or denied
      setTimeout(() => {
        Notification.requestPermission().then(permission => {
          console.log('Notification permission:', permission);
          
          // Try to enable vibration if supported
          if ('vibrate' in navigator) {
            // Test vibration with a short pattern
            navigator.vibrate([100]);
            console.log('Vibration API is supported');
          } else {
            console.log('Vibration API is not supported');
          }
        });
      }, 5000); // Delay asking for a few seconds after app load
    }
  }
  
  _flutter.loader.loadEntrypoint({
    serviceWorker: {
      serviceWorkerVersion: serviceWorkerVersion,
    },
    onEntrypointLoaded: async function(engineInitializer) {
      // Initialize engine in parallel with first data fetch
      const engineInitializerPromise = engineInitializer.initializeEngine();
      

      
      // Wait for engine to be ready
      const appRunner = await engineInitializerPromise;
      
      // Hide the loading indicator once Flutter is ready to render
      appRunner.runApp();
      
      // Transition loading state
      const loader = document.querySelector('.initial-loader');
      if (loader) {
        loader.classList.add('fade-out');
        setTimeout(() => {
          loader.style.display = 'none';
        }, 500);
      }
    }
  });
}); 