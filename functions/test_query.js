const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'rakni-v2'
});

const db = admin.firestore();

async function run() {
  try {
    console.log('Querying bookings...');
    const snapshot = await db.collection('bookings').get();
    console.log(`Total bookings: ${snapshot.size}`);
    snapshot.forEach(doc => {
      console.log(doc.id, doc.data());
    });
  } catch (err) {
    console.error('Error fetching bookings:', err);
  }
}

run();
