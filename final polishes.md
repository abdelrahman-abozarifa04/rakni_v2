```
```prompt
```

```
# Rakni v2 — Full Production Implementation Spec
```

```
> For use with Claude Code (Sonnet) — Agentic coding session
> Project: rakni-v2 | Flutter + Firebase | Egyptian Parking App
```
```

```
Here's the full MD file:
```

```
---
```

```
```markdown
```

```
# 🚗 Rakni v2 — Production Readiness Implementation Guide
```

```
**Stack:** Flutter/Dart · Firebase (Auth/Firestore/Storage/Functions) · Google
Maps
```

```
**Package:** `com.rakniteam.rakni_v2` | **Firebase Project:** `rakni-v2`
```

```
**Region:** `europe-west1` | **Target:** Android + iOS App Stores
```

```
---
```

`##` ⚠️� `GLOBAL RULES — READ BEFORE ANY CHANGE` 

`1. **NEVER hardcode hex colors** — always use `AppColors.X` from` 

- ``lib/core/theme/app_colors.dart`` 

`2. **NEVER use `.withOpacity()`** — always use `.withValues(alpha: X)`` 

`3. **NEVER use `print()`** — always use `debugPrint()`` 

`4. **NEVER recreate existing services** — extend them:` 

- ``FirestoreService.instance` — all Firestore ops` 

- ``AuthService.instance` — all Firebase Auth ops` 

- ``FavoritesService.instance` — SharedPreferences` 

- ``ImageUtils` — base64/bytes helpers` 

- ``Validators` — form validation` 

`5. **Images = base64 data URIs** in Firestore — NOT Firebase Storage URLs (except explicit exceptions)` 

`6. **All Firebase calls** must be wrapped in `try/catch` with `if (mounted)` checks before `setState`` 

`7. **Navigator.push** for feature nav · **pushAndRemoveUntil** for auth transitions only` 

`8. **Forms pattern:** `SafeArea` + `SingleChildScrollView` + `Column`` 

`9. **Currency:** EGP · **Locale:** ar_EG · **Maps center:** Cairo (30.0444, 31.2357)` 

`10. **DO NOT touch** auth flow logic unless the task explicitly says so` 

`11. Use `const` constructors wherever possible` 

`12. Every new screen must have its Navigator call shown in the parent screen` 

```
---
```

```
## 🚗 CURRENT PROJECT STRUCTURE (Reference)
```

```
```
```

```
lib/
├── core/
```

- `│   ├── models/          # BookingModel, ParkingLotModel, VehicleModel, UserModel, etc.` 

- `│   ├── services/        # FirestoreService, AuthService, FavoritesService, etc. │   ├── theme/           # AppColors │   └── utils/           # ImageUtils, Validators ├── features/` 

- `│   ├── auth/            # SignIn, Step1/2/3, AddCar, ResetPassword` 

- `│   ├── bookings/        # BookingsScreen, BookingDetailsScreen (both need work)` 

- `│   ├── home/            # HomeScreen, ParkingLotDetailScreen, SearchScreen` 

```
│   ├── map/             # MapScreen
```

- `│   ├── profile/         # ProfileScreen, MyVehiclesScreen, SettingsScreen, etc. │   ├── main/            # MainShell, BottomNavBar` 

```
│   ├── onboarding/      # OnboardingScreen
```

```
│   └── splash/          # SplashScreen
├── firebase_options.dart
└── main.dart
```
```

```
---
```

```
## 🚗 PHASE 1 — CRITICAL FIXES (Do These First)
```

```
### TASK 1.1 — Fix Google Sign-In Web Client ID
**File:** `lib/core/services/auth_service.dart`
```

```
**Problem:** Placeholder string breaks Google Sign-In on all platforms.
```

```
**Fix:** Replace this line:
```dart
static const String _webClientId =
'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
```
```

```
With the real Web Client ID from:
`Firebase Console → Authentication → Sign-in method → Google → Web SDK
configuration`
```

```
The real client ID format: `863311891829-XXXXXXXX.apps.googleusercontent.com`
Check `ios/Runner/GoogleService-Info.plist` key `CLIENT_ID` — that's the iOS
one.
```

```
The web one is in `android/app/google-services.json` under `oauth_client` with
`client_type: 3`.
```

```
---
```

```
### TASK 1.2 — Secure Exposed API Keys
```

```
**Problem:** Two API keys are hardcoded in Dart source — visible in decompiled
APK.
```

```
**Files to modify:**
1. `lib/core/services/license_ocr_service.dart` — Gemini API key
2. `lib/features/map/map_screen.dart` — Google Maps Directions API key
```

```
**Solution A — Flutter `--dart-define` (Recommended for now):**
```

```
In `lib/core/services/license_ocr_service.dart`:
```dart
// REPLACE:
static const String _apiKey = 'AIzaSyCDTtucqRKFNsPq4SsC6Q4PxDa7P5OER4k';
// WITH:
static const String _apiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);
```
In `lib/features/map/map_screen.dart`:
```dart
// REPLACE:
const _kApiKey = 'AIzaSyCI9YS3MzCZju4NbBKa04NocCG8yA1J-LI';
// WITH:
const _kApiKey = String.fromEnvironment(
  'MAPS_API_KEY',
  defaultValue: '',
```

```
);
```
```

```
Create `run_dev.sh` in project root:
```bash
#!/bin/bash
flutter run \
  --dart-define=GEMINI_API_KEY=AIzaSyCDTtucqRKFNsPq4SsC6Q4PxDa7P5OER4k \
  --dart-define=MAPS_API_KEY=AIzaSyCI9YS3MzCZju4NbBKa04NocCG8yA1J-LI
```
```

```
**Long-term Solution B:** Move OCR to a Cloud Function (proxy endpoint) — add to
Phase 4.
```

```
---
### TASK 1.3 — Fix Firestore Indexes
**File:** `firestore.indexes.json`
**Replace entire file content with:**
```json
{
  "indexes": [
    {
      "collectionGroup": "notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "reviews",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "parkingLotId", "order": "ASCENDING" },
        { "fieldPath": "timestamp", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "bookings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "bookings",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "startTime", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "parkingLots",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "availableSlots", "order": "DESCENDING" },
        { "fieldPath": "pricePerHour", "order": "ASCENDING" }
      ]
```

```
    }
  ],
  "fieldOverrides": []
}
```
```

```
Deploy with: `firebase deploy --only firestore:indexes`
```

```
---
```

```
### TASK 1.4 — Load Parking Lots from Firestore (Remove ALL Hardcoded Data)
#### Step A: Create `lib/core/repositories/parking_lot_repository.dart`
```

```
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_lot_model.dart';
import '../models/parking_slot_model.dart';
class ParkingLotRepository {
  ParkingLotRepository._();
  static final instance = ParkingLotRepository._();
  final _db = FirebaseFirestore.instance;
  // Stream all parking lots (real-time)
  Stream<List<ParkingLotModel>> streamParkingLots() {
    return _db.collection('parkingLots').snapshots().map(
      (snap) => snap.docs.map(ParkingLotModel.fromFirestore).toList(),
    );
  }
  // Stream available lots only
  Stream<List<ParkingLotModel>> streamAvailableLots() {
    return _db
        .collection('parkingLots')
        .where('availableSlots', isGreaterThan: 0)
        .snapshots()
        .map((snap) => snap.docs.map(ParkingLotModel.fromFirestore).toList());
  }
```

```
  // Get single lot
  Future<ParkingLotModel?> getLot(String lotId) async {
    final doc = await _db.collection('parkingLots').doc(lotId).get();
    if (!doc.exists) return null;
    return ParkingLotModel.fromFirestore(doc);
  }
  // Stream slots for a lot
  Stream<List<ParkingSlotModel>> streamSlots(String lotId) {
    return _db
        .collection('parkingLots')
        .doc(lotId)
        .collection('slots')
        .snapshots()
        .map((snap) => snap.docs.map(ParkingSlotModel.fromFirestore).toList());
  }
```

```
  // Search lots by name
  Future<List<ParkingLotModel>> searchLots(String query) async {
    // Firestore doesn't support full-text search natively
    // Use client-side filtering on cached data
    final snap = await _db.collection('parkingLots').get();
    final all = snap.docs.map(ParkingLotModel.fromFirestore).toList();
```

```
    final q = query.toLowerCase();
    return all.where((lot) =>
      lot.name.toLowerCase().contains(q) ||
      lot.address.toLowerCase().contains(q)
    ).toList();
  }
}
```
```

```
#### Step B: Extend `ParkingLotModel` — add `toMapData()` helper
```

```
In `lib/core/models/parking_lot_model.dart`, add:
```dart
// Convert to Map for passing between screens (avoid re-fetching)
Map<String, dynamic> toMapData() => {
  'name': name,
  'address': address,
  'slots': availableSlots,
  'price': 'EGP ${pricePerHour.toStringAsFixed(0)}/hr',
  'lat': latitude,
  'lng': longitude,
  'image': imageUrl ?? 'assets/images/mall_of_arabia.png',
  'id': id,
};
```
```

```
#### Step C: Rewrite `lib/features/home/home_screen.dart` — Nearby Parking
Section
```

```
Replace the static `_NearbyParkingCard` ListView with a
`StreamBuilder<List<ParkingLotModel>>` using
`ParkingLotRepository.instance.streamAvailableLots()`.
```

```
Keep ALL existing widget code (`_NearbyParkingCard`, `_QuickAction`,
`_FeaturedMallTile`, `_ActiveSessionCard`) — only change the DATA SOURCE.
```

```
The `_NearbyParkingCard` and `_FeaturedMallTile` already accept parameters, so
just pass real Firestore data.
```

```
#### Step D: Rewrite `lib/features/home/parking_search_screen.dart`
```

```
Replace static `_parkingLots` list with a `FutureBuilder` calling
`ParkingLotRepository.instance.searchLots(query)`.
```

```
Show `CircularProgressIndicator(color: AppColors.secondary)` while loading.
```

```
#### Step E: Rewrite `lib/features/map/map_screen.dart` — Garages from Firestore
```

```
Replace hardcoded `const List<_Garage> _garages = [...]` with a method
`_loadGaragesFromFirestore()` that calls
`ParkingLotRepository.instance.streamParkingLots()` and maps them to `_Garage`
objects.
```

```
Call this in `initState` and rebuild markers when data arrives.
```

```
#### Step F: Create Firestore Seed Data Script
```

```
Create `scripts/seed_parking_lots.js` (run via Node.js once):
```

```
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
```

```
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
```

```
const db = admin.firestore();
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
async function seed() {
  for (const lot of parkingLots) {
    const ref = await db.collection('parkingLots').add({
      ...lot,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Add 10 slots per lot
    const slotTypes = ['regular', 'regular', 'regular', 'regular',
```

```
                       'regular', 'regular', 'regular', 'regular', 'ev',
'disabled'];
    for (let i = 0; i < 10; i++) {
      await ref.collection('slots').add({
        parkingLotId: ref.id,
        slotNumber: `${String.fromCharCode(65 + Math.floor(i / 5))}${(i % 5) +
1}`,
        isAvailable: i < lot.availableSlots ? true : false,
        type: slotTypes[i],
      });
    }
    console.log(`Seeded: ${lot.name} (${ref.id})`);
  }
  console.log('Done!');
  process.exit(0);
}
seed().catch(console.error);
```
```

```
---
```

`##` 🟠 `PHASE 2 — CORE BOOKING FLOW` 

```
### TASK 2.1 — Create `BookingService`
```

```
**File:** `lib/core/services/booking_service.dart`
```

```
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../models/parking_slot_model.dart';
import 'firestore_service.dart';
class BookingService {
  BookingService._();
  static final instance = BookingService._();
```

```
  final _db = FirebaseFirestore.instance;
  // Create booking + mark slot as unavailable (transaction)
  Future<String> createBooking({
    required String parkingLotId,
    required String slotId,
    required String slotNumber,
    required DateTime startTime,
    required int durationHours,
    required double pricePerHour,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    final totalAmount = pricePerHour * durationHours;
    final endTime = startTime.add(Duration(hours: durationHours));
```

```
    return await _db.runTransaction<String>((transaction) async {
      // Check slot is still available
      final slotRef = _db
          .collection('parkingLots')
          .doc(parkingLotId)
          .collection('slots')
          .doc(slotId);
      final slotSnap = await transaction.get(slotRef);
```

```
      final slotData = slotSnap.data();
      if (slotData == null || slotData['isAvailable'] != true) {
        throw Exception('This slot is no longer available');
      }
      // Create booking
      final bookingRef = _db.collection('bookings').doc();
      transaction.set(bookingRef, {
        'userId': uid,
        'parkingLotId': parkingLotId,
        'slotId': slotId,
        'slotNumber': slotNumber,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'totalAmount': totalAmount,
        'durationHours': durationHours,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Mark slot unavailable
      transaction.update(slotRef, {'isAvailable': false});
      // Decrement lot available slots
      final lotRef = _db.collection('parkingLots').doc(parkingLotId);
      transaction.update(lotRef, {
        'availableSlots': FieldValue.increment(-1),
      });
      return bookingRef.id;
    });
  }
  // Cancel booking + free slot
  Future<void> cancelBooking(String bookingId) async {
    final bookingSnap = await _db.collection('bookings').doc(bookingId).get();
    final data = bookingSnap.data();
    if (data == null) throw Exception('Booking not found');
    if (data['status'] == 'cancelled') {
      throw Exception('Booking already cancelled');
    }
    await _db.runTransaction((transaction) async {
      final bookingRef = _db.collection('bookings').doc(bookingId);
      final slotRef = _db
          .collection('parkingLots')
          .doc(data['parkingLotId'])
          .collection('slots')
          .doc(data['slotId']);
      final lotRef = _db.collection('parkingLots').doc(data['parkingLotId']);
      transaction.update(bookingRef, {'status': 'cancelled'});
      transaction.update(slotRef, {'isAvailable': true});
      transaction.update(lotRef, {
        'availableSlots': FieldValue.increment(1),
      });
    });
  }
  // Stream user's bookings
  Stream<List<BookingModel>> streamUserBookings(String uid) {
    return _db
        .collection('bookings')
```

```
        .where('userId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BookingModel.fromFirestore).toList());
  }
  // Stream active booking for user (for home screen)
  Stream<BookingModel?> streamActiveBooking(String uid) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return BookingModel.fromFirestore(snap.docs.first);
        });
  }
  // Get booking count for user (for profile stats)
  Future<int> getUserBookingCount(String uid) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
```
---
### TASK 2.2 — Extend `BookingModel`
```

```
**File:** `lib/core/models/booking_model.dart`
Add these fields and update `fromFirestore`:
```dart
// Add to constructor and all methods:
final String slotNumber;   // e.g. "A1", "B3"
final int durationHours;   // hours booked
final String? parkingLotName;  // denormalized for display
// Add helper getter:
bool get isActive => status == 'active';
bool get isCompleted => status == 'completed';
bool get isCancelled => status == 'cancelled';
String get formattedTotal => 'EGP ${totalAmount.toStringAsFixed(0)}';
String get formattedDuration => '$durationHours ${durationHours == 1 ? "hour" :
"hours"}';
```
```

```
---
### TASK 2.3 — Create Slot Selection Screen
**File:** `lib/features/booking/slot_selection_screen.dart`
```

```
**This screen receives:** `ParkingLotModel lot`
```

```
**Layout:**
```

```
- AppBar: lot name + back button
- Top info card: available slots count, price per hour, lot address
- Duration selector: `Row` with `-` / `+` buttons and hour display (1–24 hours)
  - Price updates live: `EGP ${lot.pricePerHour * selectedHours}/total`
- Slot grid: `GridView.builder` using `StreamBuilder` on
`ParkingLotRepository.instance.streamSlots(lot.id)`
  - Each slot: `Container` with rounded corners
    - Available: `AppColors.secondary.withValues(alpha: 0.15)` background,
`AppColors.secondary` border
    - Unavailable: `AppColors.surface` background, `AppColors.fieldStroke`
border, diagonal line overlay
    - Selected: `AppColors.secondary` background, black text
    - Show slot number (A1, B2, etc.) and slot type icon
  - `regular` → `Icons.directions_car`
  - `ev` → `Icons.electric_car`
  - `disabled` → `Icons.accessible`
- Bottom bar: total price + "Confirm Slot" `ElevatedButton`
  - Disabled until a slot is selected
```

```
**On "Confirm Slot":** Navigate to `BookingConfirmationScreen` passing `lot`,
`selectedSlot`, `durationHours`.
```

```
---
```

```
### TASK 2.4 — Create Booking Confirmation Screen
```

```
**File:** `lib/features/booking/booking_confirmation_screen.dart`
```

```
**This screen receives:** `ParkingLotModel lot`, `ParkingSlotModel slot`, `int
durationHours`
```

```
**Layout:**
- AppBar: "Confirm Booking"
- Summary card with:
  - Parking lot name + address
  - Slot number + type
  - Start time: DateTime.now() formatted as "dd MMM yyyy · HH:mm"
  - End time: start + durationHours
  - Duration
  - Price breakdown: `EGP ${lot.pricePerHour}/hr × $durationHours hrs`
  - **Total: EGP X** (large, `AppColors.secondary` color)
- Payment method selector (for now: just show "Rakni Wallet" as selected)
- "Confirm & Book" `ElevatedButton`
```

```
**On confirm:**
1. Show loading spinner
2. Call `BookingService.instance.createBooking(...)`
3. On success: `Navigator.pushAndRemoveUntil` to `MainShell` + show SnackBar
"Booking confirmed! 🚗"
4. On error: show error SnackBar, stay on screen
```

```
---
```

```
### TASK 2.5 — Wire "Book Now" Button in `ParkingLotDetailScreen`
**File:** `lib/features/home/parking_lot_detail_screen.dart`
Replace the SnackBar stub in `_book()` widget:
```dart
// REPLACE:
onPressed: () => ScaffoldMessenger.of(context).showSnackBar(...)
// WITH:
```

```
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SlotSelectionScreen(lot: /* ParkingLotModel from constructor
*/),
  ),
),
```
```

```
**Note:** `ParkingLotDetailScreen` currently takes individual params (name,
address, etc.).
Either:
- **Option A (preferred):** Add a `lot` param of type `ParkingLotModel` and pass
it through
- **Option B:** Reconstruct a `ParkingLotModel` from the existing named params
```

```
---
```

```
### TASK 2.6 — Rewrite `BookingsScreen` with Real Data
**File:** `lib/features/bookings/bookings_screen.dart`
Replace hardcoded booking cards with:
```dart
StreamBuilder<List<BookingModel>>(
  stream: BookingService.instance.streamUserBookings(
    FirebaseAuth.instance.currentUser!.uid,
  ),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }
    final bookings = snapshot.data ?? [];
    if (bookings.isEmpty) {
      return _buildEmptyState(); // new private method
    }
    return ListView.separated(...);
  },
)
```
```

```
Add `_buildEmptyState()` widget: icon `Icons.local_parking_outlined` + "No
bookings yet" text + "Find Parking" button that navigates to
`ParkingSearchScreen`.
```

```
**Cancel booking:** Wire the Cancel button to:
```dart
onTap: () async {
  final confirm = await showDialog<bool>(...); // confirmation dialog
  if (confirm == true) {
    try {
      await BookingService.instance.cancelBooking(booking.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(...);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }
}
```
```

```
---
```

```
### TASK 2.7 — Fix Active Session Card in `HomeScreen`
**File:** `lib/features/home/home_screen.dart`
Replace `_ActiveSessionCard` static widget with a `StreamBuilder`:
```dart
StreamBuilder<BookingModel?>(
  stream: BookingService.instance.streamActiveBooking(
    FirebaseAuth.instance.currentUser?.uid ?? '',
  ),
  builder: (context, snapshot) {
    final booking = snapshot.data;
    if (booking == null) return _buildNoActiveSession();
    return _ActiveSessionCard(booking: booking);
  },
)
```
Update `_ActiveSessionCard` to accept `BookingModel booking` and display real
data.
```

```
Show elapsed time since `booking.startTime` using a `Timer.periodic` that
updates every minute.
```

```
---
```

```
### TASK 2.8 — Fix Real Profile Stats
**File:** `lib/features/profile/profile_screen.dart`
In `_loadUser()`, also fetch stats:
```dart
// After loading userModel, also load:
final bookingCount = await
BookingService.instance.getUserBookingCount(currentUser!.uid);
// Store in _bookingCount state variable
```
```

```
Replace hardcoded stats:
```dart
// REPLACE:
_buildStatItem('122', 'Total Parked'),
_buildStatItem('67', 'Bookings'),
_buildStatItem('4.9', 'Rating'),
// WITH:
_buildStatItem('$_bookingCount', 'Bookings'),
_buildStatItem('${(_bookingCount * 0.8).round()}', 'Total Parked'),
_buildStatItem(_bookingCount > 0 ? '4.8' : '—', 'Rating'),
```
```

```
---
```

```
### TASK 2.9 — Add QR Code to Booking Details
**Add to `pubspec.yaml`:**
```yaml
qr_flutter: ^4.1.0
```
**File:** `lib/features/bookings/booking_details_screen.dart`
Replace `const Icon(Icons.qr_code_2, ...)` with:
```dart
```

```
QrImageView(
  data: 'RAKNI-BOOKING-${booking.id}',
  version: QrVersions.auto,
  size: 200,
  backgroundColor: Colors.white,
  errorCorrectionLevel: QrErrorCorrectLevel.M,
)
```
---
```

`##` 🟡 `PHASE 3 — MISSING FEATURES ### TASK 3.1 — Create Notifications Screen **Add to `pubspec.yaml`:** ```yaml firebase_messaging: ^15.1.3 ```` 

```
**File:** `lib/features/notifications/notifications_screen.dart`
**Layout:**
- AppBar: "Notifications" + "Mark all read" button (TextButton)
- `StreamBuilder` on `FirestoreService.instance.streamNotifications(uid)`
- Each notification: `ListTile`
  - Leading: icon based on `notification.type`:
    - `booking_reminder` → `Icons.access_time` (amber)
    - `payment_success` → `Icons.check_circle` (AppColors.secondary)
    - `booking_confirmed` → `Icons.local_parking` (AppColors.secondary)
    - default → `Icons.notifications`
  - Title: `notification.title`
  - Subtitle: `notification.body`
  - Trailing: timestamp (relative: "2m ago", "1h ago", "Yesterday")
  - Unread: slightly lighter background `AppColors.surface` vs
`AppColors.background`
  - `onTap`: call `FirestoreService.instance.markNotificationAsRead(id)` +
navigate based on type
- Empty state: `Icons.notifications_none` + "No notifications yet"
**Wire to HomeScreen:** Replace notification bell `IconButton` in
`_buildTopBar()`:
```dart
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
),
```
Add badge count using `StreamBuilder` counting unread notifications.
**FCM Setup (Firebase Messaging):**
In `lib/main.dart`, add FCM initialization:
```dart
// Request permission + get token
await FirebaseMessaging.instance.requestPermission(
  alert: true, badge: true, sound: true,
);
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null && uid != null) {
  await FirestoreService.instance.saveUserData(uid, {'fcmToken': fcmToken});
}
```

```
// Handle background messages
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```
```

```
---
```

```
### TASK 3.2 — Create Reviews System UI
```

```
**File:** `lib/features/reviews/add_review_screen.dart`
```

```
**This screen receives:** `String parkingLotId`, `String parkingLotName`
```

```
**Layout:**
- AppBar: "Rate Your Experience"
- Lot name display
- Star rating widget: 5 `IconButton` with `Icons.star` (filled
`AppColors.secondary` / outlined `AppColors.hintColor`)
- Comment `TextField` (multiline, 5 rows max)
- "Submit Review" `ElevatedButton`
```

```
**On submit:**
```dart
await FirestoreService.instance.addReview(ReviewModel(
  id: '',
  userId: currentUser.uid,
  userName: userModel.fullName,
  parkingLotId: parkingLotId,
  rating: selectedRating.toDouble(),
  comment: commentController.text.trim(),
  timestamp: DateTime.now(),
));
```
```

```
**File:** `lib/features/reviews/reviews_list_widget.dart` (reusable widget)
```

```
A `Column` containing:
```

- `Rating summary (average stars + count)` 

- ``StreamBuilder` on `FirestoreService.instance.streamParkingLotReviews(lotId)`` 

- `Each review: avatar circle (initials), name, star rating, comment, date` 

```
**Wire to `ParkingLotDetailScreen`:**
```

- `Replace fake rating row `'4.8' / '234 reviews'` with `StreamBuilder` reading real reviews` 

- `Add "Reviews" section below the map widget using `ReviewsListWidget`` 

- `Add floating "Rate" button if user has a completed booking for this lot` 

```
---
```

```
### TASK 3.3 — Fix Favourites Navigation
```

```
**File:** `lib/features/home/favourites_screen.dart`
```

```
The `_favourites` is a `Set<String>` of lot names. To navigate to detail:
```

`1. Add `ParkingLotRepository.instance` import` 

`2. On tile tap, `await ParkingLotRepository.instance.searchLots(name)` to get the full model` 

`3. Navigate to `ParkingLotDetailScreen` with the found model` 

`4. Show loading indicator on the tile while fetching` 

```
---
```

```
### TASK 3.4 — Wire Filter Bottom Sheet
```

```
**File:** `lib/features/home/filter_bottom_sheet.dart`
```

```
Change `FilterBottomSheet.show()` to return `FilterConfig`:
```dart
// Create filter model:
class FilterConfig {
  final double minPrice;
  final double maxPrice;
  final double maxDistance;
  final Set<String> slotTypes;
  const FilterConfig({...});
}
// Return from show():
static Future<FilterConfig?> show(BuildContext context) async {
  return showModalBottomSheet<FilterConfig>(...);
}
// On "Apply Filters":
Navigator.pop(context, FilterConfig(
  minPrice: _priceRange.start,
  maxPrice: _priceRange.end,
  maxDistance: _maxDistance,
  slotTypes: Set.from(_selectedSlotTypes),
));
```
```

```
In `HomeScreen._buildSearchBar()` and `ParkingSearchScreen`, receive the
`FilterConfig` and filter results accordingly.
```

```
---
```

```
### TASK 3.5 — Persist Settings
```

```
**File:** `lib/features/profile/settings_screen.dart`
```

```
Add `SharedPreferences` persistence for all toggles:
```

```
1. Load settings in `initState`:
```dart
Future<void> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _pushNotifications = prefs.getBool('setting_push_notifications') ?? true;
    _emailNotifications = prefs.getBool('setting_email_notifications') ?? false;
    _parkingReminders = prefs.getBool('setting_parking_reminders') ?? true;
    _promotions = prefs.getBool('setting_promotions') ?? false;
    _locationServices = prefs.getBool('setting_location_services') ?? true;
    _darkMode = prefs.getBool('setting_dark_mode') ?? true;
    _language = prefs.getString('setting_language') ?? 'English';
    _currency = prefs.getString('setting_currency') ?? 'EGP';
  });
}
```
```

```
2. Save on every change:
```dart
// In each onChanged callback:
onChanged: (v) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('setting_push_notifications', v);
  setState(() => _pushNotifications = v);
},
```
```

`3. For **Language** change: wrap `MaterialApp` in `main.dart` with a `ValueNotifier<Locale>` and update it from settings.` 

`4. For **Dark Mode**: Add theme switching — `MaterialApp` already has `ThemeData`, add `ThemeData.light()` variant and switch based on setting.` 

```
---
```

```
### TASK 3.6 — Wire Help & Support Real Actions
```

```
**Add to `pubspec.yaml`:**
```yaml
url_launcher: ^6.3.0
```
```

```
**File:** `lib/features/profile/help_support_screen.dart`
```

```
Replace SnackBar stubs:
```dart
// Live Chat — open WhatsApp or Intercom
onTap: () async {
  final uri = Uri.parse('https://wa.me/+201XXXXXXXXX?text=Hello+Rakni+Support');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
},
// Email Us
onTap: () async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'support@rakni.app',
    query: 'subject=Rakni Support Request',
  );
  if (await canLaunchUrl(uri)) await launchUrl(uri);
},
// Call Us
onTap: () async {
  final uri = Uri(scheme: 'tel', path: '+20XXXXXXXXX');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
},
// Rate the App — open Play Store / App Store
onTap: () async {
  final uri = Uri.parse(
    Platform.isAndroid
      ? 'market://details?id=com.rakniteam.rakni_v2'
      : 'https://apps.apple.com/app/idXXXXXXXXX',
  );
  if (await canLaunchUrl(uri)) await launchUrl(uri);
},
```
---
```

```
### TASK 3.7 — Create Transaction History Screen
**File:** `lib/features/transactions/transaction_history_screen.dart`
```

```
**Layout:**
- AppBar: "Transaction History"
- Balance card at top: current wallet balance from
`FirestoreService.instance.getWallet(uid)`
- `StreamBuilder` on transactions (add `streamTransactions(uid)` to
```

```
`FirestoreService`)
- Each transaction: amount, type, date, status badge
- Filter tabs: "All" / "Bookings" / "Top-ups"
- Empty state
**Add to `FirestoreService`:**
```dart
Stream<List<TransactionModel>> streamUserTransactions(String uid) {
  return _transactions
      .where('userId', isEqualTo: uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map(TransactionModel.fromFirestore)
          .toList());
}
```
```

```
**Wire to ProfileScreen:** Add "Transaction History" menu item between "Payment
Methods" and "Settings".
```

```
---
```

```
### TASK 3.8 — Create Wallet Screen
```

```
**File:** `lib/features/wallet/wallet_screen.dart`
```

- `**Layout:** - Gradient card showing balance: "EGP XXX.XX" - "Add Money" button → `TopUpScreen` - Recent transactions list (last 5, link to full history)` 

```
**File:** `lib/features/wallet/top_up_screen.dart`
```

```
**Layout:**
- Quick amount chips: EGP 50 / 100 / 200 / 500
- Custom amount field
```

```
- Payment method: (Visa/Mastercard cards from payment_methods_screen)
- "Top Up" button
```

```
**Note:** For MVP, update wallet balance directly in Firestore. Real payment
gateway in Phase 4.
```

```
---
```

`##` 🟢 `PHASE 4 — POLISH & STORE READY ### TASK 4.1 — App Icons Generate app icons using Flutter launcher icons: **Add to `pubspec.yaml`:** ```yaml dev_dependencies: flutter_launcher_icons: ^0.14.1 flutter_launcher_icons: android: true ios: true image_path: "assets/images/app_icon.png"  # 1024x1024 PNG, no transparency min_sdk_android: 21 adaptive_icon_background: "#2A2A2B" adaptive_icon_foreground: "assets/images/app_icon_foreground.png" ```` 

```
Run: `flutter pub run flutter_launcher_icons`
```

```
---
```

```
### TASK 4.2 — Create Privacy Policy & Terms Screens
```

```
**File:** `lib/features/legal/privacy_policy_screen.dart`
```

```
**Layout:**
- AppBar: "Privacy Policy"
- `SingleChildScrollView` with `Markdown` widget (or styled `Text` paragraphs)
- Last updated date
```

```
**File:** `lib/features/legal/terms_screen.dart`
```

```
Same structure for Terms of Service.
```

```
**Wire to:**
- `SettingsScreen` → "Privacy Policy" + "Terms of Service" items
- `OnboardingScreen` → small text at bottom "By continuing, you agree to our
Terms & Privacy Policy"
- `CreateAccountStep1Screen` → below the info box
```

```
---
```

```
### TASK 4.3 — Firebase Crashlytics + Analytics
**Add to `pubspec.yaml`:**
```yaml
firebase_crashlytics: ^4.1.3
firebase_analytics: ^11.3.3
```
```

```
**In `main.dart`:**
```dart
// Crashlytics
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
// Analytics — track key events:
// - booking_created
// - booking_cancelled
// - lot_viewed
// - search_performed
```
```

```
---
```

```
### TASK 4.4 — Skip Car / Add Car from Profile
**File:** `lib/features/auth/add_car_screen.dart`
Add a "Skip for now" `TextButton` below the main button:
```dart
TextButton(
  onPressed: () => Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (route) => false,
  ),
```

```
  child: const Text(
    'Skip for now',
    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
  ),
),
```
---
### TASK 4.5 — Duplicate Plate Number Validation
**File:** `lib/features/auth/add_car_screen_2.dart` and
`lib/features/profile/my_vehicles_screen.dart`
Before saving, check for duplicate plate:
```dart
// Add to FirestoreService:
Future<bool> isPlateNumberTaken(String uid, String plateNumber) async {
  final snap = await _users
      .doc(uid)
      .collection('vehicles')
      .where('plateNumber', isEqualTo: plateNumber)
      .limit(1)
      .get();
  return snap.docs.isNotEmpty;
}
```
Call before `addVehicle()`:
```dart
final taken = await FirestoreService.instance.isPlateNumberTaken(uid, plate);
if (taken) {
  _showSnackBar('This plate number is already registered');
  return;
}
```
---
```

```
### TASK 4.6 — Error Handling — Global Consistency
Create `lib/core/utils/error_handler.dart`:
```dart
class AppErrorHandler {
  static String parse(dynamic error) {
    final msg = error.toString().replaceFirst('Exception: ', '');
    if (msg.contains('network')) return 'Network error. Check your connection.';
    if (msg.contains('permission')) return 'Permission denied.';
    if (msg.contains('not-found')) return 'Data not found.';
    return msg;
  }
  static void showSnackBar(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppErrorHandler.parse(error)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
```
```

```
Replace all `_showSnackBar(e.toString())` patterns across all screens with
`AppErrorHandler.showSnackBar(context, e)`.
```

```
---
```

```
### TASK 4.7 — Loading States Consistency
Create `lib/core/widgets/loading_overlay.dart`:
```dart
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ColoredBox(
            color: Color(0x80000000),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }
}
```
```

```
Use in booking confirmation, profile update, etc.
```

```
---
```

```
### TASK 4.8 — Deep Link Verification for Android
```

```
**File:** `android/app/src/main/AndroidManifest.xml`
```

```
The intent filter for `rakni-v2.firebaseapp.com` is already there ✓
```

```
Add Digital Asset Links verification:
1. Create `public/.well-known/assetlinks.json` in Firebase Hosting
2. Run: `flutter run` on a physical device and verify deep links work
```

```
---
### TASK 4.9 — Performance — Image Caching
**Add to `pubspec.yaml`:**
```yaml
cached_network_image: ^3.4.1
```
```

```
In any place that shows parking lot images from URLs (future Firebase Storage
URLs):
```dart
// REPLACE Image.network() with:
```

```
CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
  placeholder: (_, __) => Container(color: AppColors.surface),
  errorWidget: (_, __, ___) => Image.asset(
    'assets/images/mall_of_arabia.png',
    fit: BoxFit.cover,
  ),
)
```
```

```
---
```

`##` 📋 `FILES TO CREATE (Complete List)` 

```
```
```

```
lib/
├── core/
│   ├── repositories/
│   │   └── parking_lot_repository.dart       ← TASK 1.4
│   ├── services/
│   │   └── booking_service.dart              ← TASK 2.1
│   ├── widgets/
│   │   └── loading_overlay.dart              ← TASK 4.7
│   └── utils/
│       └── error_handler.dart                ← TASK 4.6
│
├── features/
│   ├── booking/
│   │   ├── slot_selection_screen.dart        ← TASK 2.3
│   │   └── booking_confirmation_screen.dart  ← TASK 2.4
│   ├── notifications/
│   │   └── notifications_screen.dart         ← TASK 3.1
│   ├── reviews/
│   │   ├── add_review_screen.dart            ← TASK 3.2
│   │   └── reviews_list_widget.dart          ← TASK 3.2
│   ├── wallet/
│   │   ├── wallet_screen.dart                ← TASK 3.8
│   │   └── top_up_screen.dart                ← TASK 3.8
│   ├── transactions/
│   │   └── transaction_history_screen.dart   ← TASK 3.7
│   └── legal/
│       ├── privacy_policy_screen.dart        ← TASK 4.2
│       └── terms_screen.dart                 ← TASK 4.2
│
scripts/
└── seed_parking_lots.js                      ← TASK 1.4
```
```

```
---
```

`##` 📦 `PACKAGES TO ADD (Final `pubspec.yaml` additions)` 

```
```yaml
dependencies:
  qr_flutter: ^4.1.0            # QR codes in booking details
  url_launcher: ^6.3.0          # Help & support real actions
  firebase_messaging: ^15.1.3   # Push notifications
  cached_network_image: ^3.4.1  # Image caching
dev_dependencies:
  flutter_launcher_icons: ^0.14.1  # App icons generation
  firebase_crashlytics: ^4.1.3     # Crash reporting (add to dependencies)
  firebase_analytics: ^11.3.3      # Analytics (add to dependencies)
```

```
```
```

```
---
```

`##  FIRESTORE SECURITY RULES UPDATES` 🔒 

```
**File:** `firestore.rules`
```

`Add rules for new collections: ```javascript // Add inside the main match block: match /bookings/{bookingId} { allow read: if request.auth != null && request.auth.uid == resource.data.userId; allow create: if request.auth != null && request.auth.uid == request.resource.data.userId; allow update: if request.auth != null && request.auth.uid == resource.data.userId && request.resource.data.status == 'cancelled'; } match /parkingLots/{lotId} { allow read: if request.auth != null; allow write: if false; // admin only via Cloud Functions match /slots/{slotId} { allow read: if request.auth != null; allow write: if false; // only via transaction in BookingService (admin SDK) } } match /reviews/{reviewId} { allow read: if request.auth != null; allow create: if request.auth != null && request.auth.uid == request.resource.data.userId; } match /transactions/{txId} { allow read: if request.auth != null && request.auth.uid == resource.data.userId; allow write: if false; // Cloud Functions only } match /wallets/{userId} { allow read: if request.auth != null && request.auth.uid == userId; allow write: if false; // Cloud Functions only } match /notifications/{notifId} { allow read: if request.auth != null && request.auth.uid == resource.data.userId; allow update: if request.auth != null && request.auth.uid == resource.data.userId && request.resource.data.keys().hasOnly(['isRead']); } ``` --##` 📊 `IMPLEMENTATION ORDER (Recommended Session Flow) ``` Session 1 (Security + Foundation):` 

```
  1.1 → 1.2 → 1.3 → 1.4 (seed script + repository)
```

```
Session 2 (Booking Core):
  2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6
Session 3 (Real Data Everywhere):
  2.7 → 2.8 → 2.9 → 3.3 → 3.4
Session 4 (Features):
  3.1 → 3.2 → 3.5 → 3.6 → 3.7 → 3.8
Session 5 (Store Ready):
  4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6 → 4.7 → 4.8 → 4.9
```
```

```
---
```

