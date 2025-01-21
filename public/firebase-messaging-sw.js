importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js');
// // Initialize the Firebase app in the service worker by passing the generated config

const firebaseConfig = {
  apiKey: "AIzaSyC9s2koB7q0fUJ5kKlOZGkOvZxnYqa7xpA",
  authDomain: "tocken-57cce.firebaseapp.com",
  projectId: "tocken-57cce",
  storageBucket: "tocken-57cce.firebasestorage.app",
  messagingSenderId: "681332319946",
  appId: "1:681332319946:web:b8d06c532fc9db81733633",
  measurementId: "G-5XNHW4LZ95"
};

firebase?.initializeApp(firebaseConfig)


// Retrieve firebase messaging
const messaging = firebase.messaging();

self.addEventListener('install', function (event) {
  console.log('Hello world from the Service Worker :call_me_hand:');
});

// Handle background messages
self.addEventListener('push', function (event) {
  const payload = event.data.json();
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  event.waitUntil(
    self.registration.showNotification(notificationTitle, notificationOptions)
  );
});