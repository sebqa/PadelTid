// Optimized Flutter loading
window.addEventListener('load', function() {
  // Check if serviceWorkerVersion is defined, use null if not
  const serviceWorkerVersion = self.serviceWorkerVersion || null;
  
  // Request notification permission for PWA
  if ('Notification' in window) {
    if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
      // Only ask if not already granted or denied
      setTimeout(() => {
        Notification.requestPermission().then(permission => {
          console.log('Notification permission:', permission);
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
      
      // Prefetch data in parallel with engine initialization
      try {
        const prefetchPromise = fetch(
          'https://tco4ce372f.execute-api.eu-north-1.amazonaws.com/getPadelTid?wind_speed_threshold=10.0&precipitation_probability_threshold=50.0&temperature_threshold=0.0&showUnavailableSlots=true&locations='
        );
        console.log('Prefetching data for faster startup');
      } catch (e) {
        console.log('Prefetch failed, will load data normally', e);
      }
      
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