# Firestore Database Structure - Rakni v2

This document outlines the Firestore collection and document structure used in the Rakni v2 application.

## Collections Overview

| Collection | Description | Sub-collections |
| :--- | :--- | :--- |
| `users` | User profile data | `vehicles` |
| `parkingLots` | Details of parking lots | `slots` |
| `bookings` | Parking reservation records | - |
| `transactions` | Payment and wallet transaction history | - |
| `wallets` | User balance information | - |
| `notifications` | In-app notification messages | - |
| `reviews` | User reviews for parking lots | - |
| `cars` | Legacy or top-level car information | - |

---

## 1. `users` Collection
Stores core user information.

**Document ID:** User UID (from Firebase Auth)

| Field | Type | Description |
| :--- | :--- | :--- |
| `fullName` | String | User's full name |
| `email` | String | User's email address |
| `nationalId` | String | User's national identification number |
| `age` | String | User's age |
| `gender` | String | User's gender |
| `address` | String | User's home or default address |
| `phoneNumber` | String | User's contact number |
| `createdAt` | Timestamp | Account creation time |
| `updatedAt` | Timestamp | Last profile update time |

### Sub-collection: `vehicles`
Stores vehicles owned by a specific user.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `brand` | String | Vehicle brand (e.g., Toyota) |
| `model` | String | Vehicle model (e.g., Corolla) |
| `plateNumber` | String | License plate number |
| `color` | String | Vehicle color |
| `isDefault` | Boolean | Whether this is the primary vehicle |
| `createdAt` | Timestamp | When the vehicle was added |

---

## 2. `parkingLots` Collection
Stores information about available parking facilities.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | String | Name of the parking lot |
| `address` | String | Full address of the facility |
| `latitude` | Double | GPS Latitude |
| `longitude` | Double | GPS Longitude |
| `totalSlots` | Integer | Total capacity |
| `availableSlots` | Integer | Currently vacant slots |
| `pricePerHour` | Double | Rate per hour in local currency |
| `imageUrl` | String (Optional) | URL to facility image |

### Sub-collection: `slots`
Individual parking spots within a lot.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `parkingLotId` | String | Reference to parent parking lot |
| `slotNumber` | String | Identifier for the spot (e.g., A1, B4) |
| `isAvailable` | Boolean | Current availability status |
| `type` | String | Spot type: `regular`, `disabled`, `ev` |

---

## 3. `bookings` Collection
Records of all parking reservations.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `userId` | String | Reference to the user who booked |
| `parkingLotId` | String | Reference to the parking lot |
| `slotId` | String | Reference to the specific slot |
| `startTime` | Timestamp | Reservation start time |
| `endTime` | Timestamp (Optional) | Reservation end time |
| `totalAmount` | Double | Final cost of the booking |
| `status` | String | `pending`, `active`, `completed`, `cancelled` |

---

## 4. `transactions` Collection
Financial transaction logs.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `bookingId` | String | Reference to the associated booking |
| `userId` | String | Reference to the user |
| `amount` | Double | Transaction amount |
| `paymentMethod` | String | e.g., `wallet`, `credit_card` |
| `timestamp` | Timestamp | Time of transaction |
| `status` | String | `success`, `failed`, `pending` |

---

## 5. `wallets` Collection
User digital wallet balance.

**Document ID:** User UID

| Field | Type | Description |
| :--- | :--- | :--- |
| `balance` | Double | Current available funds |
| `currency` | String | Default: `EGP` |
| `lastUpdated` | Timestamp | Server-side update timestamp |

---

## 6. `notifications` Collection
User notifications.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `title` | String | Notification header |
| `body` | String | Notification content |
| `timestamp` | Timestamp | When notification was sent |
| `isRead` | Boolean | Read status |
| `type` | String | `booking_reminder`, `payment_success`, etc. |

---

## 7. `reviews` Collection
User feedback on parking lots.

**Document ID:** Auto-generated ID

| Field | Type | Description |
| :--- | :--- | :--- |
| `userId` | String | Reference to the reviewer |
| `userName` | String | Name displayed with review |
| `parkingLotId` | String | Reference to the reviewed lot |
| `rating` | Double | Score (usually 1.0 - 5.0) |
| `comment` | String | Review text |
| `timestamp` | Timestamp | Review date |

---

## 8. `cars` Collection (Legacy/Redundant)
*Note: This collection is used by some services but duplicates data found in user-specific vehicle sub-collections.*

**Document ID:** User UID

| Field | Type | Description |
| :--- | :--- | :--- |
| `plateNumber` | String | License plate number |
| `carModel` | String | Vehicle model |
| `carColor` | String | Vehicle color |
| `manufacturingYear`| String | Year of manufacture |
| `updatedAt` | Timestamp | Last update time |
