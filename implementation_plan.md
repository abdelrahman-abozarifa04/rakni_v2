# Booking & Exit Flow — Full Implementation Plan

Build all 10 screens for the parking booking lifecycle (Booking → Entry → Active Session → Exit) as defined in [gemini-code-1779476550960.md](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/gemini-code-1779476550960.md), wired to Firestore and the existing codebase.

## User Review Required

> [!IMPORTANT]
> **BookingModel extension**: The plan adds 6 new fields (`vehicleId`, `vehiclePlate`, `pricePerHour`, `reservationId`, `level`, `spotLabel`) to `BookingModel` and its `toFirestore`/`fromFirestore` methods. This is backward-compatible (all nullable with defaults), but existing Firestore booking docs will have empty values for these fields.

> [!WARNING]
> **ParkingSlotModel extension**: The slot model needs a `level` field added. This assumes your Firestore `parkingLots/{id}/slots` documents already have a `level` field, or we'll default to `"Level 1"`.

> [!IMPORTANT]
> **API Integration**: The ngrok API (`/api/vehicle/entry/`, `/api/vehicle/exit/`) appears to be for hardware gate systems. The app screens will **simulate** the ANPR scan flow on the mobile side. If you want actual HTTP calls to the API, confirm and I'll add them. Currently the plan treats entry/exit recognition as a timed simulation matching the Figma designs.

## Open Questions

> [!IMPORTANT]
> **Promo codes**: Should promo code validation be a Firestore lookup, a Cloud Function call, or just UI-only for now?

> [!IMPORTANT]
> **Payment methods (Visa/Mastercard)**: Are these stored in Firestore, or is it UI-only selection with the wallet being the only real payment method?

---

## Proposed Changes

The implementation is broken into **5 phases**, each self-contained and testable.

---

### Phase 1: Model Extensions & Service Updates

Extend existing models and `FirestoreService` with the new fields and methods needed by all 10 screens.

#### [MODIFY] [booking_model.dart](file:///c:/Users/ASUS/rakni_v2/lib/core/models/booking_model.dart)
- Add fields: `vehicleId`, `vehiclePlate`, `pricePerHour`, `reservationId`, `level`, `spotLabel`
- Update `fromFirestore` and `toFirestore` to include these fields
- Update `copyWith` to include these fields

#### [MODIFY] [parking_slot_model.dart](file:///c:/Users/ASUS/rakni_v2/lib/core/models/parking_slot_model.dart)
- Add `level` field (default `"Level 1"`)
- Update `fromFirestore`, `toFirestore`, `copyWith`

#### [MODIFY] [firestore_service.dart](file:///c:/Users/ASUS/rakni_v2/lib/core/services/firestore_service.dart)
- Add `streamUserBookings(uid)` → real-time stream of user bookings
- Add `getActiveBooking(uid)` → stream for active booking (status == 'active', limit 1)
- Add `updateBookingStatus(bookingId, status)` → update booking status
- Add `updateBookingEndTime(bookingId, endTime)` → extend session
- Add `getParkingLot(lotId)` → get single parking lot by ID
- Add `streamParkingSlots(lotId)` → real-time stream of slots

---

### Phase 2: Booking Flow (Screens 1–3)

The core booking form, slot selection grid, and confirmation screen.

#### [NEW] [booking_details_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/booking_details_screen.dart)
**SCREEN 1** — Full booking form matching [Booking-step 1.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Booking-step%201.png)
- Receives `ParkingLotModel`
- Parking lot info card (image, name, address, distance, rate)
- Vehicle selector dropdown (streams from `streamVehicles(uid)`)
- Parking spot field → navigates to Screen 2, returns `ParkingSlotModel`
- Date picker, From/To time pickers, Duration display
- Payment method selector (Wallet with balance, Card options)
- Promo code field
- Price summary (Subtotal, Service, Total)
- "Confirm & Pay" → creates booking in Firestore → navigates to Screen 3

#### [NEW] [booking_spot_selection_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/booking_spot_selection_screen.dart)
**SCREEN 2** — Parking spot grid matching [Booking-step 2.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Booking%20spot%20selection%20Booking-step%202.png)
- Receives `ParkingLotModel`
- Level filter chips (Level 1, 2, 3, 4)
- Type filter chips (All Spots, Available Only, EV Charging)
- Grid of parking slots from `streamParkingSlots(lotId)` 
- Slot states: available (green border + label), EV (blue + ⚡), occupied (grey car), disabled (♿), selected (lime glow)
- Bottom bar: selected spot info + "Done" button → pops with `ParkingSlotModel`
- Uses `GridView.builder` with `CustomPaint` cells

#### [NEW] [booking_confirmed_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/booking_confirmed_screen.dart)
**SCREEN 3** — Confirmation matching [Booking-step 3.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Booking-step%203.png)
- Animated checkmark icon in lime circle
- Booking ID, Expiry time pill
- Location card, Date/Time cards, Vehicle card
- "Seamless Entry Enabled" banner
- "Back to Home" (outlined) and "Navigate to Parking" (lime filled → Screen 4)

---

### Phase 3: Navigation & Entry (Screens 4–6)

#### [NEW] [outdoor_navigation_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/outdoor_navigation_screen.dart)
**SCREEN 4** — Navigation matching [Navigation to parking Booking-step 4.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Navigation%20to%20parking%20Booking-step%204.png)
- Google Map with route polyline from current location to parking lot
- Turn-by-turn overlay card
- Bottom bar: ETA, distance, arrival time
- Close button and navigation button
- "You've Arrived" state → "Start Parking" button → Screen 5

#### [NEW] [gate_entry_scan_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/gate_entry_scan_screen.dart)
**SCREEN 5** — Entry scan matching [Gate Entry-1.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Gate%20Entry-1.png) and [Gate Entry-2.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Gate%20Entry-2.png)
- State 1: Camera viewfinder placeholder, corner brackets, animated scan line, "Please wait for scanning..."
- State 2: Vehicle recognized, plate displayed, green checkmark, "Access Granted"
- Instructions card (3 steps)
- Fallback buttons: "Scan QR Code", "Manual Entry"
- Auto-advances to Screen 6 after 3 seconds
- Updates booking status to 'active' in Firestore

#### [NEW] [indoor_navigate_to_spot_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/indoor_navigate_to_spot_screen.dart)
**SCREEN 6** — Indoor navigation matching [Navigation to spot.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Navigation%20to%20spot.png)
- 2D top-down parking grid with `CustomPaint`
- Target slot glows with lime pulsing animation
- Dashed path line from entry to target
- Instruction overlay
- "Done" button → navigates to Screen 7

---

### Phase 4: Active Session & Extension (Screens 7–8)

#### [NEW] [active_session_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/active_session_screen.dart)
**SCREEN 7** — Session tracker matching [Active session.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Active%20session.png)
- Circular timer ring: `CustomPainter` + `AnimationController` (lime stroke filling clockwise)
- Center: "Active Session" pill with pulsing green dot, HH:MM:SS elapsed time
- Cost card: Entry time, Rate, "Current Cost" updating every second
- Details: Vehicle, Reservation ID, Location, Spot, Time Slot, Date
- "Extend Session" → opens Screen 8
- "End Session" → navigates to Screen 9
- Uses `Timer.periodic(Duration(seconds: 1))` for real-time updates
- Disposes timer and animation controller properly

#### [NEW] [extend_session_bottom_sheet.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/extend_session_bottom_sheet.dart)
**SCREEN 8** — Extension sheet matching [Extend session.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Extend%20session.png)
- Current session summary (ID, Vehicle, Spot, Duration, Cost)
- Extension duration picker (hours/minutes stepper)
- New end time display
- Payment method selector
- Price summary (Extension fee, Current fee, Service, Total)
- "Confirm & Pay" → updates `endTime` in Firestore, records transaction

---

### Phase 5: Exit Flow & Wiring (Screens 9–10 + Updates)

#### [NEW] [gate_exit_scan_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/gate_exit_scan_screen.dart)
**SCREEN 9** — Exit scan matching [Gate Exit-1.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Gate%20Exit-1.png)
- Header: "Ending Your Session..." 
- Same viewfinder UI as entry but with exit instructions
- State 1: Scanning animation
- State 2: Plate recognized, fee calculated
- Auto-advances to Screen 10

#### [NEW] [final_payment_details_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/booking/final_payment_details_screen.dart)
**SCREEN 10** — Payment matching [Payment-1.png](file:///c:/Users/ASUS/Downloads/booking%20%26%20exit%20flows%20screens/Payment-1.png)
- Vehicle plate recognition banner
- Session summary table (Location, Spot, Entry/Exit time, Duration)
- Payment method selector
- Pricing breakdown (Parking fee, Overstay fee, Subtotal, Discount, Total)
- "Pay XX LE" → updates booking status to 'completed', deducts wallet, records transaction
- Success → navigates to Home

#### [MODIFY] [parking_lot_detail_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/home/parking_lot_detail_screen.dart)
- Wire "Book Now" button to navigate to `BookingDetailsScreen` with `ParkingLotModel`

#### [MODIFY] [bookings_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/bookings/bookings_screen.dart)
- Load real bookings from Firestore via `getUserBookings(uid)`
- Active booking → "View Details" → `ActiveSessionScreen`
- Dynamic status badges with correct colors

#### [MODIFY] [home_screen.dart](file:///c:/Users/ASUS/rakni_v2/lib/features/home/home_screen.dart)
- Update `_ActiveSessionCard` to stream active booking from Firestore
- Show real data (lot name, elapsed time, cost)
- "End" button → navigates to exit flow

---

## Verification Plan

### Automated Tests
- `flutter analyze` — zero errors on all new files
- `flutter build apk --debug` — successful build

### Manual Verification
- Navigate from `ParkingLotDetailScreen` → "Book Now" → full flow through all 10 screens
- Verify Firestore documents are created/updated correctly at each step
- Verify timer updates every second on `ActiveSessionScreen`
- Verify all animations (scan line, circular timer, pulsing spot) render smoothly
- Verify wallet balance deduction on payment
