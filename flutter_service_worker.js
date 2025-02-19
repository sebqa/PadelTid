'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"firebase-messaging-sw.js": "de0d1d3675e7c8dafeae062bb3a3867e",
"icons/Icon-maskable-512.png": "66f9f6e0e7d638a36b3dc8dab648550c",
"icons/logo512.png": "52be4b54810c942781d2b6078124c745",
"icons/Icon-512.png": "66f9f6e0e7d638a36b3dc8dab648550c",
"icons/logo192.png": "7553c387987812d42e212932af36374a",
"icons/Icon-maskable-192.png": "98fd3d26a3bc29dc9dbf030867deea5a",
"icons/Icon-192.png": "98fd3d26a3bc29dc9dbf030867deea5a",
"flutter_bootstrap.js": "81a7260d18f5310ac5b33206e16ba40b",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "ba4a8ae1a65ff3ad81c6818fd47e348b",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.js": "6cfe36b4647fbfa15683e09e7dd366bc",
"cookie_policy.html": "480fa81a42b57224975fc9b73bd82382",
"main.dart.js": "62aeaadbc3f8a70e582243887fad74e2",
"version.json": "15235b5108d6a877ef74fe3317a96bf7",
"CNAME": "6291463553dfea136690757c08a9bd5f",
"assets/packages/firebase_ui_auth/fonts/SocialIcons.ttf": "c6d1e3f66e3ca5b37c7578e6f80f37d8",
"assets/FontManifest.json": "804c79ec8cdd623f079f6e2bf5d0b9af",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "7f5955bfd7267504fdc5d164ac350629",
"assets/assets/weather_symbols/darkmode/02n.svg": "3852ffb60ddf397c3a126b11ee17b281",
"assets/assets/weather_symbols/darkmode/24d.svg": "915ba31020ebaaed0e173855b7b29712",
"assets/assets/weather_symbols/darkmode/01m.svg": "2b6f6b4597fa42282901c39139fb63f5",
"assets/assets/weather_symbols/darkmode/29d.svg": "409ce8350efce192a54f73e33462a7bf",
"assets/assets/weather_symbols/darkmode/40d.svg": "e7eb5a7b893ba6d596cf74afd0a8fa03",
"assets/assets/weather_symbols/darkmode/44d.svg": "6a9b9e5cb106618cb4334684e2ee923a",
"assets/assets/weather_symbols/darkmode/20m.svg": "34493fbe2b0fe950a7ec14585a0af272",
"assets/assets/weather_symbols/darkmode/44n.svg": "99267ff0a50103bd5b61cea1ea3fedb8",
"assets/assets/weather_symbols/darkmode/07d.svg": "bc1b1e4c84a949ea973507ed436b43b2",
"assets/assets/weather_symbols/darkmode/13.svg": "d84298fcaa2bcb67a440fd83fccc496c",
"assets/assets/weather_symbols/darkmode/29m.svg": "3f43bb3dc77ab72387b42bd54b281268",
"assets/assets/weather_symbols/darkmode/28m.svg": "f608a4de75ecf66bdb4fd71756b8c018",
"assets/assets/weather_symbols/darkmode/05m.svg": "0b3ab64eceb9f65a2d6e5ace80cd49b4",
"assets/assets/weather_symbols/darkmode/43m.svg": "9d25809917eb148b46735745d3db63c9",
"assets/assets/weather_symbols/darkmode/41d.svg": "12ec3e6a346d3b1f4429ccd10ffd225a",
"assets/assets/weather_symbols/darkmode/31.svg": "d0223537a2e306d14f83720b54065332",
"assets/assets/weather_symbols/darkmode/06d.svg": "303f5754bbe6c955c1a3adc237fac337",
"assets/assets/weather_symbols/darkmode/08d.svg": "a57217e900d87ec4cc4af04c34a7c390",
"assets/assets/weather_symbols/darkmode/14.svg": "1f17b7a05951390ced2d92d8555ea76d",
"assets/assets/weather_symbols/darkmode/06n.svg": "1e2e9064ebedbb19497944212272747d",
"assets/assets/weather_symbols/darkmode/27m.svg": "564ffcfea7b919f7431fa65cfde2e5de",
"assets/assets/weather_symbols/darkmode/22.svg": "834f5f0d4ea13b9720ca161f6f10bca8",
"assets/assets/weather_symbols/darkmode/03n.svg": "e9a596dc1b75c96fdf653e5f3ae2818b",
"assets/assets/weather_symbols/darkmode/07n.svg": "f917128fa87675917a9b43d1bbd15c04",
"assets/assets/weather_symbols/darkmode/33.svg": "6c95773bbea34bc4d08d847cf117cc91",
"assets/assets/weather_symbols/darkmode/49.svg": "a7ddc1909a008cee592bbe540637c689",
"assets/assets/weather_symbols/darkmode/48.svg": "2b1a3b16f92238fc4bed8eb16463d57c",
"assets/assets/weather_symbols/darkmode/08m.svg": "9c954ab5d1a22ad2aababc2862dad5bb",
"assets/assets/weather_symbols/darkmode/26n.svg": "5d1a9d7ed752faa918ff263bbfc453d4",
"assets/assets/weather_symbols/darkmode/42m.svg": "9ea0774fd232e882b1c4609d2c7c6e82",
"assets/assets/weather_symbols/darkmode/34.svg": "3a0778e0c6ed40a4d0973de8b6920a32",
"assets/assets/weather_symbols/darkmode/02d.svg": "de4ce652a1d34467b048b451aeb98d3d",
"assets/assets/weather_symbols/darkmode/03d.svg": "99518b75c24ea7d79a5105cae78b69cd",
"assets/assets/weather_symbols/darkmode/42d.svg": "8462419acb031d40db4a13fe8525c0d7",
"assets/assets/weather_symbols/darkmode/47.svg": "b8e5aacc911a6bd236d267f09e2bf963",
"assets/assets/weather_symbols/darkmode/43d.svg": "59c9e4db31d7b8975bb00eb822bae659",
"assets/assets/weather_symbols/darkmode/50.svg": "7a6cedaa45736b396b45518cb64a9c7c",
"assets/assets/weather_symbols/darkmode/09.svg": "b55912d6c7a930c7242004321b6ddbd7",
"assets/assets/weather_symbols/darkmode/02m.svg": "f363c2b0d0b52eefef5d59ceb4b040f8",
"assets/assets/weather_symbols/darkmode/26d.svg": "1e5e924e66a4319e1fb8223be1aa8f0e",
"assets/assets/weather_symbols/darkmode/41m.svg": "96b89dd43d19fe7e062c6db22a6f9785",
"assets/assets/weather_symbols/darkmode/28n.svg": "7787b730155f7bcd91bcbc2029436f69",
"assets/assets/weather_symbols/darkmode/40m.svg": "c85727a77e0fd91dffa152d5527fb061",
"assets/assets/weather_symbols/darkmode/41n.svg": "e1b6f321af0d2b20a5a1ca84ec4642ef",
"assets/assets/weather_symbols/darkmode/05d.svg": "beb3cda7ecdb715f48c47e6422855297",
"assets/assets/weather_symbols/darkmode/01d.svg": "02db4c93fc0b99b789be32c915eee1e7",
"assets/assets/weather_symbols/darkmode/30.svg": "1d6151cf4bfdbf3d1e307d19c93bf858",
"assets/assets/weather_symbols/darkmode/21n.svg": "4145ae77a79dc2ba5eea9e4589f292e8",
"assets/assets/weather_symbols/darkmode/45d.svg": "0f4ef7ff9696b50d2f45cded0c53d6d4",
"assets/assets/weather_symbols/darkmode/46.svg": "81786edcf50a1063e272c37122ec7c23",
"assets/assets/weather_symbols/darkmode/20d.svg": "89c446b1a644028145b7afee5c50af78",
"assets/assets/weather_symbols/darkmode/28d.svg": "307e50d2ed045e5964da322b67dba3cb",
"assets/assets/weather_symbols/darkmode/21d.svg": "3ae95fe6fd388120fc0289fe93c9ee6a",
"assets/assets/weather_symbols/darkmode/44m.svg": "42b00f7e0cbc0d336bdd286ce81adc26",
"assets/assets/weather_symbols/darkmode/12.svg": "79838746876032ba38f1499fa126688e",
"assets/assets/weather_symbols/darkmode/11.svg": "78339250be27600e8b574870ce0fe869",
"assets/assets/weather_symbols/darkmode/21m.svg": "f5224acce34a4344a3656bcde0bbb68a",
"assets/assets/weather_symbols/darkmode/10.svg": "637305d6127891fc50520b47b25ec21b",
"assets/assets/weather_symbols/darkmode/08n.svg": "46e28da218732a6a3fd8f797509ceab0",
"assets/assets/weather_symbols/darkmode/03m.svg": "07a950054a4cf180a4e2eac5ed2fb200",
"assets/assets/weather_symbols/darkmode/06m.svg": "a773df5b57efdfeeca34866c9c7a6bd3",
"assets/assets/weather_symbols/darkmode/25n.svg": "5cd76244094793c243681a6c9bf7d759",
"assets/assets/weather_symbols/darkmode/25m.svg": "e7a2670e5f647fece71924995bbea7b1",
"assets/assets/weather_symbols/darkmode/29n.svg": "ea29bb36e18326c6858050a3bda854e5",
"assets/assets/weather_symbols/darkmode/24n.svg": "a9332fd12e5bb68974f911b35e2697a4",
"assets/assets/weather_symbols/darkmode/23.svg": "7f640acf37917a9d96c22bd401b2b229",
"assets/assets/weather_symbols/darkmode/26m.svg": "1427fb83a3f8d760ee82bed0a1893d07",
"assets/assets/weather_symbols/darkmode/01n.svg": "4633dea37d97c3a09eafebb7d4217f05",
"assets/assets/weather_symbols/darkmode/40n.svg": "9fc0cab27c3736e28ad3506985157bd8",
"assets/assets/weather_symbols/darkmode/45n.svg": "98a8791945976c22fb64d50d218441a9",
"assets/assets/weather_symbols/darkmode/42n.svg": "78bd281f4171aacc618cf5b47f1b5341",
"assets/assets/weather_symbols/darkmode/27n.svg": "b838cd85fdbadc620db3b112347c68dc",
"assets/assets/weather_symbols/darkmode/04.svg": "d1f842c53f3a193d8ca8e1619b16e70a",
"assets/assets/weather_symbols/darkmode/25d.svg": "d21221343d5bc7c9aa1eb3499c3fa776",
"assets/assets/weather_symbols/darkmode/15.svg": "7676a7efbe892c07bb4a9678009c8903",
"assets/assets/weather_symbols/darkmode/24m.svg": "42e599497cd6212634f1d348e1d1b450",
"assets/assets/weather_symbols/darkmode/45m.svg": "def9de14a559eed3caae56a8f6e53769",
"assets/assets/weather_symbols/darkmode/05n.svg": "e576e01108b4deb02563b3b589d782a4",
"assets/assets/weather_symbols/darkmode/32.svg": "6e086487f24af304189a7d0d9dbbc6cc",
"assets/assets/weather_symbols/darkmode/20n.svg": "60924b2970690be162130b57a7dda61f",
"assets/assets/weather_symbols/darkmode/43n.svg": "25722b4255eb4c46253dac96a095e272",
"assets/assets/weather_symbols/darkmode/27d.svg": "81126727023782736a8f922b9d2ab521",
"assets/assets/weather_symbols/darkmode/07m.svg": "cebe6012e0ecb8a96b61a8cd093ae31b",
"assets/assets/images/4698abd180d4266f723d.svg": "bf3dfc4d85413ef6137902612f066457",
"assets/NOTICES": "005dca024bc5722009977d668c86c561",
"assets/AssetManifest.bin": "47b935a5169567aeeb8b8d07eb5429ee",
"assets/fonts/MaterialIcons-Regular.otf": "b83603b9946f6a50c489f72c34e3ff5a",
"assets/AssetManifest.bin.json": "9390e1b10517689e6b6224978569aa6b",
"favicon.png": "50add57b1b2374117053e59f38fd5532",
"index.html": "1fc51bbf922c644f603c9a1e97e6f901",
"/": "1fc51bbf922c644f603c9a1e97e6f901",
"manifest.json": "8eb6f51051ae910ff7b0015b6c115784",
"flutter.js": "76f08d47ff9f5715220992f993002504"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
