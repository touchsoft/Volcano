'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "63d746880684888991a7223cc7d22f45",
"version.json": "f449fa1184840b24dabe24823ef32240",
"index.html": "fbe8a0929d547a97a6acf185d6a09c65",
"/": "fbe8a0929d547a97a6acf185d6a09c65",
"main.dart.js": "1fcf3d6c5430486c020f1b5e68b83575",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "5f4e44d1afbb7b3b83230a8e7e656710",
"assets/AssetManifest.json": "62041e5a8b00ac83803a6c3f118d4dc2",
"assets/NOTICES": "b02581d885b3688381ef81cc1715befa",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "4d1a4fcce87848d4100926a96faa23e2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_sound/assets/js/tau_web.js": "32cc693445f561133647b10d1b97ca07",
"assets/packages/flutter_sound/assets/js/async_processor.js": "1665e1cb34d59d2769956d2f14290274",
"assets/packages/flutter_sound_web/howler/howler.js": "3030c6101d2f8078546711db0d1a24e9",
"assets/packages/flutter_sound_web/src/flutter_sound_recorder.js": "0ec45f8c46d7ddb18691714c0c7348c8",
"assets/packages/flutter_sound_web/src/flutter_sound_player.js": "b14f8d190230d77c02ffc51ce962ce80",
"assets/packages/flutter_sound_web/src/flutter_sound_stream_processor.js": "48d52b8f36a769ea0e90cf9e58eddfa7",
"assets/packages/flutter_sound_web/src/flutter_sound.js": "3c26fcc60917c4cbaa6a30a231f7d4d8",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "356bf2400976fe8b5db8e8eef8927156",
"assets/fonts/MaterialIcons-Regular.otf": "c0ad29d56cfe3890223c02da3c6e0448",
"assets/assets/images/truck-225.png": "b3225b4fbb02b47984cc65cf328dfa0c",
"assets/assets/images/truck-180.png": "3981f986fd5f37213526f664a71ad538",
"assets/assets/images/truck-90.png": "27294db742f63b68ba5806d148bc114c",
"assets/assets/images/rock-grey.png": "d6160a037de03aada027fb346a65e7b9",
"assets/assets/images/truck-45.png": "32f3a40014829de70862e64f68aaa297",
"assets/assets/images/toolbox.png": "ba0ac711b141526b4b12c8f05d5d1703",
"assets/assets/images/volcano.png": "75afb8fd9e7058465adacde840da18a7",
"assets/assets/images/truck-135.png": "2018f38f62230c7ce4fa023001957e86",
"assets/assets/images/island3.png": "643efba0bc3a1c68dfde17189f15045d",
"assets/assets/images/island2.png": "cad7d1f53f263b4de8db27efeee4ec95",
"assets/assets/images/truck-270.png": "23fa53902b68bcb72eab93f47d2b7c62",
"assets/assets/images/truck-315.png": "052d052993d16a5e947cd393a63e5cb0",
"assets/assets/images/rock-red.png": "cd42ebce092561720a15a048a2d598c2",
"assets/assets/images/truck-0.png": "4c870114d7e7dcf84dff0de255c296b3",
"assets/assets/images/volcano2.png": "5b31c6c7ad773e5a24c30464af70842c",
"assets/assets/images/truck-invert.png": "e0fe90610ae61f081b601ee20f9a0576",
"assets/assets/images/truck.png": "27c5670d23422cd1743834ee15686680",
"assets/assets/audio/repair.mp3": "50a0ef3edc7f8a88cd5242442c498c58",
"assets/assets/audio/bonus.mp3": "68d0b216441eb70c3c7620441a2ee1c3",
"assets/assets/audio/rumble.mp3": "26b65ff6fe5da79cf5c28fa393e7c7d2",
"assets/assets/audio/crash4.mp3": "fe816ac03636df5e1d672dad2df05c97",
"assets/assets/audio/collected.mp3": "1dafb3d10adf5fee12532bf566ac277b",
"assets/assets/audio/crash3.mp3": "01ce069b74010b1b218f969e82840339",
"assets/assets/audio/crash2.mp3": "022b3e89ce21d2b1eb5b90028c493ed1",
"assets/assets/audio/crash1.mp3": "864cf937e9aa7b4f129b72f757fd8597",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
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
