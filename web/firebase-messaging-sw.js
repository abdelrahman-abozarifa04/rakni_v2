// Service Worker for Firebase Cloud Messaging on Web.
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js");

// Initialize Firebase App in service worker.
firebase.initializeApp({
  apiKey: "AIzaSyDK4L0cuEu3gx94JJ-iS2HxF98C0S9UUgY",
  appId: "1:863311891829:web:9c89a571264ea24c3a173c",
  messagingSenderId: "863311891829",
  projectId: "rakni-v2",
  authDomain: "rakni-v2.firebaseapp.com",
  storageBucket: "rakni-v2.firebasestorage.app"
});

const messaging = firebase.messaging();

// Optional background message handler:
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message: ', payload);
  
  const notificationTitle = payload.notification.title || "Rakni Update";
  const notificationOptions = {
    body: payload.notification.body || "You have a new update.",
    icon: "/favicon.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
