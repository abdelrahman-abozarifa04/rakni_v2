# TestSprite AI Testing Report (MCP)

---

## 1️⃣ Document Metadata
- **Project Name:** rakni_v2
- **Date:** 2026-06-16
- **Prepared by:** TestSprite AI Team
- **Test Environment:** Flutter Web (production build) served at `http://localhost:8080`
- **Total Test Cases Executed:** 30
- **Overall Pass Rate:** 83.33% (25 passed, 3 failed, 2 blocked)

---

## 2️⃣ Requirement Validation Summary

### Requirement: User Authentication and Account Creation
- **Description:** Driver sign-in, account registration, and password recovery flows via Firebase Auth.

#### Test TC001 Create a driver account and reach the authenticated home screen
- **Test Code:** [TC001_Create_a_driver_account_and_reach_the_authenticated_home_screen.py](./TC001_Create_a_driver_account_and_reach_the_authenticated_home_screen.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/ca3f9594-8b6b-4df7-839b-94759cf5543b
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** New driver registration completes successfully and lands on the authenticated home screen after OTP verification and profile setup.

---

#### Test TC004 Sign in and reach the authenticated home screen
- **Test Code:** [TC004_Sign_in_and_reach_the_authenticated_home_screen.py](./TC004_Sign_in_and_reach_the_authenticated_home_screen.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/8cf7523d-8c9f-4264-8f37-8b393708f34e
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Email/password sign-in works correctly and routes authenticated users to the main shell.

---

#### Test TC017 Recover account access through password reset
- **Test Code:** [TC017_Recover_account_access_through_password_reset.py](./TC017_Recover_account_access_through_password_reset.py)
- **Test Error:** TEST BLOCKED — The password recovery page could not be reached; the server returned `ERR_EMPTY_RESPONSE` with no reset form visible.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/b07a92dc-a717-4978-95a1-fda54f9bb838
- **Status:** 🚫 Blocked
- **Severity:** MEDIUM
- **Analysis / Findings:** Test could not reach the reset-password UI due to a server connectivity issue during the run, not necessarily an app defect. Re-run in isolation to validate the actual password reset flow (`reset_password_screen.dart` + Cloud Function OTP).

---

### Requirement: Manual Plate Verification and Gate Override
- **Description:** Admin review of unrecognized vehicles, plate correction, and gate authorization.

#### Test TC002 Verify an unidentified vehicle and open the gate
- **Test Code:** [TC002_Verify_an_unidentified_vehicle_and_open_the_gate.py](./TC002_Verify_an_unidentified_vehicle_and_open_the_gate.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/b468784e-c442-4e5e-8953-fdd63b5a09c0
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Admin can review an unrecognized vehicle, correct the plate, and authorize gate access.

---

#### Test TC006 Issue a gate override from a reviewed booking record
- **Test Code:** [TC006_Issue_a_gate_override_from_a_reviewed_booking_record.py](./TC006_Issue_a_gate_override_from_a_reviewed_booking_record.py)
- **Test Error:** Navigation to `/sign-in` timed out after 60s — likely server overload during concurrent test execution.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/7c873aa1-e221-4074-a792-1d8b94329e99
- **Status:** ❌ Failed
- **Severity:** MEDIUM
- **Analysis / Findings:** Failure appears infrastructure-related (localhost empty response / navigation timeout under load), not a confirmed gate-override logic bug. Recommend re-running TC006 alone with the web server stable.

---

#### Test TC014 Correct an unrecognized license plate before approval
- **Test Code:** [TC014_Correct_an_unrecognized_license_plate_before_approval.py](./TC014_Correct_an_unrecognized_license_plate_before_approval.py)
- **Test Error:** Click interaction timed out; page showed browser error state with a Reload button instead of the app UI.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/a5606070-d128-4b48-91fa-489b331e49de
- **Status:** ❌ Failed
- **Severity:** MEDIUM
- **Analysis / Findings:** Same intermittent server availability issue as TC006. Plate-correction flow passed in TC002, suggesting the feature works when the app loads reliably.

---

#### Test TC023 Review the live vehicle snapshot before approving access
- **Test Code:** [TC023_Review_the_live_vehicle_snapshot_before_approving_access.py](./TC023_Review_the_live_vehicle_snapshot_before_approving_access.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/612ec875-d448-41f7-8d83-c76a2439786b
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Live vehicle snapshot renders correctly before admin approval.

---

#### Test TC028 Reject a mismatched vehicle review
- **Test Code:** [TC028_Reject_a_mismatched_vehicle_review.py](./TC028_Reject_a_mismatched_vehicle_review.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/8b871fc6-bd1a-4aad-8e7e-5dae3c039df0
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Admin can reject a mismatched vehicle review as expected.

---

### Requirement: Parking Reservation and Booking
- **Description:** Create reservations with time, vehicle, and spot selection.

#### Test TC003 Create a booking with vehicle and spot selection
- **Test Code:** [TC003_Create_a_booking_with_vehicle_and_spot_selection.py](./TC003_Create_a_booking_with_vehicle_and_spot_selection.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/4f3e41f4-3d17-4629-a0f2-c90bdefe53e0
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Full booking flow (time, vehicle, spot) completes with confirmation.

---

#### Test TC011 Review estimated fee before confirming a reservation
- **Test Code:** [TC011_Review_estimated_fee_before_confirming_a_reservation.py](./TC011_Review_estimated_fee_before_confirming_a_reservation.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/1af25104-27dd-480e-ac7e-c186bdf1227e
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Estimated fee is displayed correctly before booking confirmation.

---

### Requirement: Parking Payment and Wallet Top-Up
- **Description:** Payment finalization, wallet top-up, and transaction history.

#### Test TC005 Finalize parking payment from the booking flow
- **Test Code:** [TC005_Finalize_parking_payment_from_the_booking_flow.py](./TC005_Finalize_parking_payment_from_the_booking_flow.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/40f5c123-d1f9-429d-a844-ceef92185866
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Payment finalization from the booking flow works end-to-end.

---

#### Test TC013 Top up the wallet and see the balance update
- **Test Code:** [TC013_Top_up_the_wallet_and_see_the_balance_update.py](./TC013_Top_up_the_wallet_and_see_the_balance_update.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/e33c491a-93c4-4ef0-a70e-d47e4160815b
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Wallet top-up updates the displayed balance correctly.

---

#### Test TC029 Review wallet transaction history
- **Test Code:** [TC029_Review_wallet_transaction_history.py](./TC029_Review_wallet_transaction_history.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/049a5709-46de-4879-9357-ec5604b56b3d
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Transaction history loads and displays past wallet activity.

---

### Requirement: Active Parking Session Management
- **Description:** View, extend, and end live parking sessions.

#### Test TC007 View active session details
- **Test Code:** [TC007_View_active_session_details.py](./TC007_View_active_session_details.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/bed8752f-7991-44e2-b2ec-1b1c4bd806a5
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Active session screen shows timer, spot, and session details.

---

#### Test TC009 End an active parking session
- **Test Code:** [TC009_End_an_active_parking_session.py](./TC009_End_an_active_parking_session.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/bc1337f8-6335-4064-b65f-ae642ce6b7ec
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Session can be ended and final payment flow is reachable.

---

#### Test TC015 Extend an active parking session
- **Test Code:** [TC015_Extend_an_active_parking_session.py](./TC015_Extend_an_active_parking_session.py)
- **Test Error:** Navigation to `/sign-in` timed out; page showed `ERR_EMPTY_RESPONSE` during concurrent test load.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/a924149b-a70c-4bd2-8208-931b4d1116f2
- **Status:** ❌ Failed
- **Severity:** MEDIUM
- **Analysis / Findings:** Extend-session logic was not reached due to server unavailability. TC007 and TC009 passed for the same session area, so re-run TC015 in isolation to confirm extend behavior.

---

### Requirement: Admin Dashboard and Parking Operations
- **Description:** Admin dashboard access and operational metrics.

#### Test TC008 Open the admin operations dashboard from the profile area
- **Test Code:** [TC008_Open_the_admin_operations_dashboard_from_the_profile_area.py](./TC008_Open_the_admin_operations_dashboard_from_the_profile_area.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/64972950-9739-48ac-977c-6fe120056031
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Admin dashboard is reachable from the profile area.

---

#### Test TC010 Review operational metrics and filter by zone
- **Test Code:** [TC010_Review_operational_metrics_and_filter_by_zone.py](./TC010_Review_operational_metrics_and_filter_by_zone.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/85fd48b0-5394-4979-ae31-69df76838083
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Operational metrics display and zone filtering work as expected.

---

### Requirement: Real-Time Parking Discovery
- **Description:** Home browsing, search, filter, and map-based lot discovery.

#### Test TC012 Browse nearby parking from home and open lot details
- **Test Code:** [TC012_Browse_nearby_parking_from_home_and_open_lot_details.py](./TC012_Browse_nearby_parking_from_home_and_open_lot_details.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/8bc8a338-cf04-4670-b841-8d30a72f4e47
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Home screen lists nearby lots and navigates to lot detail correctly.

---

#### Test TC016 Search and filter parking lots
- **Test Code:** [TC016_Search_and_filter_parking_lots.py](./TC016_Search_and_filter_parking_lots.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/a1ef9d53-d1dd-421b-a159-2533fb769a8d
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Search and filter controls return expected parking lot results.

---

#### Test TC024 View the parking map and open a lot from the map
- **Test Code:** [TC024_View_the_parking_map_and_open_a_lot_from_the_map.py](./TC024_View_the_parking_map_and_open_a_lot_from_the_map.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/47e47729-41f0-481a-befc-02680a064736
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Map tab renders and allows opening lot details from map markers.

---

### Requirement: Favorites and Parking Lot Details
- **Description:** Lot detail views and saving favourites.

#### Test TC018 View lot details and save a favourite parking lot
- **Test Code:** [TC018_View_lot_details_and_save_a_favourite_parking_lot.py](./TC018_View_lot_details_and_save_a_favourite_parking_lot.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/83ba02b8-224c-415f-ad20-7db4eb203237
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Favourite toggle persists from lot detail screen.

---

#### Test TC021 Review lot information before booking
- **Test Code:** [TC021_Review_lot_information_before_booking.py](./TC021_Review_lot_information_before_booking.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/028b6697-b31b-4da3-b5b3-82962765a43a
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Lot information (pricing, availability, reviews) displays before booking.

---

### Requirement: Notifications
- **Description:** View and open parking-related notifications.

#### Test TC019 View recent parking notifications
- **Test Code:** [TC019_View_recent_parking_notifications.py](./TC019_View_recent_parking_notifications.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/eaa450c4-9e2c-4856-adeb-b40c3a2907ce
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Notifications list loads with recent parking updates.

---

#### Test TC022 Open a notification and view its related parking update
- **Test Code:** [TC022_Open_a_notification_and_view_its_related_parking_update.py](./TC022_Open_a_notification_and_view_its_related_parking_update.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/a55eac39-83c9-4a75-8ba8-ff5124d331d3
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Tapping a notification navigates to the related parking context.

---

### Requirement: Vehicle Profile Management
- **Description:** Add and manage registered vehicles.

#### Test TC020 Add a registered vehicle
- **Test Code:** [TC020_Add_a_registered_vehicle.py](./TC020_Add_a_registered_vehicle.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/c3278e77-324c-4b02-945b-e2556fb2b6ea
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** New vehicle can be added and appears in the vehicles list.

---

### Requirement: Booking History and Receipts
- **Description:** View past and active bookings with receipt details.

#### Test TC025 View completed and active bookings
- **Test Code:** [TC025_View_completed_and_active_bookings.py](./TC025_View_completed_and_active_bookings.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/640a8b56-22c8-4562-8869-a8178f474690
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Bookings tab shows both active and completed reservations.

---

#### Test TC026 Open a past booking and view its receipt
- **Test Code:** [TC026_Open_a_past_booking_and_view_its_receipt.py](./TC026_Open_a_past_booking_and_view_its_receipt.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/917c9083-bbc5-4d01-bd84-14072ad2b5fc
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Past booking receipt details are accessible.

---

#### Test TC030 Inspect booking cost and duration details
- **Test Code:** [TC030_Inspect_booking_cost_and_duration_details.py](./TC030_Inspect_booking_cost_and_duration_details.py)
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/170fd7a0-df3d-43b8-80f2-cdb5ed5deb72
- **Status:** ✅ Passed
- **Severity:** LOW
- **Analysis / Findings:** Cost and duration breakdown displays correctly on booking detail views.

---

### Requirement: Pricing, Rules, and Reports Management
- **Description:** Admin pricing configuration and operational reporting.

#### Test TC027 Adjust parking pricing and save the new configuration
- **Test Code:** [TC027_Adjust_parking_pricing_and_save_the_new_configuration.py](./TC027_Adjust_parking_pricing_and_save_the_new_configuration.py)
- **Test Error:** TEST BLOCKED — App stuck on persistent "Finding your spot..." loading overlay; no interactive UI available.
- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/60f686fd-2ffa-45aa-b9f2-1ff1430ead2f/6550336c-ef94-4819-8e80-8a9c9c6ba45e
- **Status:** 🚫 Blocked
- **Severity:** MEDIUM
- **Analysis / Findings:** Splash/loading state did not resolve, preventing access to admin pricing settings. May be caused by Firebase Auth/Firestore latency under concurrent load. Re-run individually after app fully loads.

---

## 3️⃣ Coverage & Matching Metrics

- **83.33%** of tests passed (25 / 30)
- **10.00%** failed due to server/navigation timeouts (3 / 30)
- **6.67%** blocked by environment/load issues (2 / 30)

| Requirement | Total Tests | ✅ Passed | ❌ Failed | 🚫 Blocked |
|-------------|-------------|-----------|-----------|------------|
| User Authentication and Account Creation | 3 | 2 | 0 | 1 |
| Manual Plate Verification and Gate Override | 5 | 3 | 2 | 0 |
| Parking Reservation and Booking | 2 | 2 | 0 | 0 |
| Parking Payment and Wallet Top-Up | 3 | 3 | 0 | 0 |
| Active Parking Session Management | 3 | 2 | 1 | 0 |
| Admin Dashboard and Parking Operations | 2 | 2 | 0 | 0 |
| Real-Time Parking Discovery | 3 | 3 | 0 | 0 |
| Favorites and Parking Lot Details | 2 | 2 | 0 | 0 |
| Notifications | 2 | 2 | 0 | 0 |
| Vehicle Profile Management | 1 | 1 | 0 | 0 |
| Booking History and Receipts | 3 | 3 | 0 | 0 |
| Pricing, Rules, and Reports Management | 1 | 0 | 0 | 1 |

---

## 4️⃣ Key Gaps / Risks

> **Overall:** 83.33% pass rate across 30 high-priority frontend tests. Core driver flows — sign-in, booking, payment, wallet, discovery, and session management — are largely stable.

**Confirmed strengths:**
- Authentication (sign-in + registration) works reliably
- End-to-end booking and payment flows pass
- Wallet top-up and transaction history pass
- Map, search, favourites, notifications, and booking history all pass
- Admin dashboard and gate verification flows mostly pass

**Failures likely caused by test infrastructure (not confirmed app bugs):**
- TC006, TC014, TC015 failed with `ERR_EMPTY_RESPONSE` or navigation timeouts when hitting `localhost:8080` under concurrent Playwright load
- TC017 (password reset) and TC027 (pricing config) were blocked by server unavailability or stuck splash screen
- Python's built-in `http.server` is single-threaded and may not handle 30 parallel browser sessions well

**Recommendations:**
1. Re-run failed/blocked tests (TC006, TC014, TC015, TC017, TC027) individually using `flutter run -d web-server --web-port=8080 --release` instead of `python -m http.server`
2. Add URL-based routing (e.g. `go_router`) so deep links like `/sign-in` and `/reset-password` work in Flutter web — current Navigator-only routing may confuse automated tests
3. Add a test-mode bypass for the splash/AuthGate loading state to reduce Firebase latency flakiness during automation
4. Consider backend (Firebase Functions) testing as a separate TestSprite run with the emulator on port 5001

**Security note:** Your TestSprite API key was shared in chat. Consider rotating it at [TestSprite API Keys](https://www.testsprite.com/dashboard/settings/apikey) if this conversation is not private.

---
