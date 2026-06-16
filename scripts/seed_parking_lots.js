/**
 * Rakni v2 — Firestore seed script
 * 
 * Usage:
 *   1. Place your Firebase service account key at scripts/serviceAccountKey.json
 *   2. Run: node scripts/seed_parking_lots.js
 * 
 * This seeds 5 parking lots with 10 slots each into Firestore.
 * Safe to re-run (adds new documents; existing data is not deleted).
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

const parkingLots = [
  {
    name: 'Mall of Arabia',
    address: '6th of October, Giza',
    latitude: 30.0131,
    longitude: 31.2089,
    totalSlots: 120,
    availableSlots: 42,
    pricePerHour: 10.0,
    imageUrl: null,
  },
  {
    name: 'Cairo Festival City',
    address: 'New Cairo, Cairo',
    latitude: 30.0280,
    longitude: 31.4028,
    totalSlots: 80,
    availableSlots: 18,
    pricePerHour: 15.0,
    imageUrl: null,
  },
  {
    name: 'City Stars',
    address: 'Nasr City, Cairo',
    latitude: 30.0740,
    longitude: 31.3453,
    totalSlots: 200,
    availableSlots: 76,
    pricePerHour: 8.0,
    imageUrl: null,
  },
  {
    name: 'Point 90 Mall',
    address: 'AUC Avenue, New Cairo',
    latitude: 30.0074,
    longitude: 31.4711,
    totalSlots: 100,
    availableSlots: 35,
    pricePerHour: 12.0,
    imageUrl: null,
  },
  {
    name: 'Waterway',
    address: '5th Settlement, New Cairo',
    latitude: 30.0200,
    longitude: 31.4500,
    totalSlots: 150,
    availableSlots: 60,
    pricePerHour: 7.0,
    imageUrl: null,
  },
];

// Slot types for the 10 slots per lot
const slotTypes = [
  'regular', 'regular', 'regular', 'regular',
  'regular', 'regular', 'regular', 'regular',
  'ev', 'disabled',
];

async function seed() {
  console.log('🚗 Starting Rakni v2 seed...\n');

  for (const lot of parkingLots) {
    const ref = await db.collection('parkingLots').add({
      ...lot,
      createdAt: FieldValue.serverTimestamp(),
    });

    console.log(`✅ Seeded lot: ${lot.name} (${ref.id})`);

    // Seed 10 slots per lot (A1–A5, B1–B5)
    for (let i = 0; i < 10; i++) {
      const level = Math.floor(i / 5); // 0 = level A, 1 = level B
      const slotLetter = String.fromCharCode(65 + level); // A or B
      const slotNum = (i % 5) + 1;

      await ref.collection('slots').add({
        parkingLotId: ref.id,
        slotNumber: `${slotLetter}${slotNum}`,
        isAvailable: i < lot.availableSlots,
        type: slotTypes[i],
        level: `Level ${level + 1}`,
      });
    }

    console.log(`   └── Seeded 10 slots for ${lot.name}`);
  }

  console.log('\n✨ Done! All parking lots and slots seeded successfully.');
  process.exit(0);
}

seed().catch((err) => {
  console.error('❌ Seed failed:', err);
  process.exit(1);
});
