// media_sw.js — Media bypass service worker
// Bypasses Service Worker completely for Firebase Storage, media files, and byte-range requests.
//
// Root causes solved:
// 1. ERR_CACHE_OPERATION_NOT_SUPPORTED:
//    Cache API cannot store HTTP 206 Partial Content (returned by video Range streaming).
// 2. MEDIA_ERR_SRC_NOT_SUPPORTED:
//    In Chromium, when a Service Worker intercepts cross-origin media requests via event.respondWith(),
//    the response becomes opaque (status: 0, headers hidden). Chrome's media element cannot read
//    Content-Type or Content-Range from opaque responses and aborts with MEDIA_ERR_SRC_NOT_SUPPORTED.
//
// By simply NOT calling event.respondWith() on media/storage requests, the browser falls back
// to its native C++ network stack, streaming native Range/206 responses with zero interception.

const BYPASS_HOSTS = [
  'firebasestorage.googleapis.com',
  'firebasestorage.app',
  'appspot.com',
];

self.addEventListener('fetch', function (event) {
  const url = event.request.url;
  const isStorageUrl = BYPASS_HOSTS.some(host => url.includes(host));
  const isRangeRequest = event.request.headers.has('range');
  const isMediaFile = /\.(mp4|webm|ogg|mov|m4v|mp3|wav)(\?.*)?$/i.test(url);

  if (isStorageUrl || isRangeRequest || isMediaFile) {
    // Return early without calling event.respondWith() so the browser handles it natively.
    return;
  }
});

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

