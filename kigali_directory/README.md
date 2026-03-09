# Kigali Directory

A Flutter mobile app for discovering and managing public services and places in Kigali, Rwanda. Built with Firebase for real-time data sync, Google Maps for location features, and Provider for state management.

---

## What it does

The app lets users browse a directory of places and services across Kigali — restaurants, hospitals, schools, banks, and more. Anyone with an account can add their own listings, edit them, and have them show up instantly for other users. There's a full map view where all listings appear as pins, and you can get directions to any place directly from the app.

---

## Features

**Authentication**
- Sign up with name, email, and password
- Email verification required before accessing the app
- Login / logout with proper session handling

**Directory & Search**
- Browse all listings across 11 categories
- Search by name in real time
- Filter by category with live result counts
- See distance to each listing (if location permission is granted)

**Your Listings**
- Add new places with name, category, address, contact info, description, and GPS coordinates
- Edit or delete your own listings
- Changes reflect everywhere immediately via Firestore streams

**Maps**
- Embedded Google Map on each listing's detail page with a marker at the listing's location
- Full-screen map tab showing all listings as interactive markers
- Tap a marker to see a summary card
- "Get Directions" opens Google Maps with the destination pre-filled

**Settings**
- View your profile (name, email, verification status)
- Toggle notification preferences (stored locally with SharedPreferences)
- Sign out

---

## Screens

| Screen | What it's for |
|---|---|
| Login | Sign in with email and password |
| Sign Up | Create a new account |
| Verify Email | Prompts you to check your inbox before continuing |
| Directory | Browse, search, and filter all listings |
| My Listings | See and manage listings you've created |
| Listing Form | Add a new listing or edit an existing one |
| Listing Detail | Full details + embedded map + directions |
| Map View | All listings on one full-screen map |
| Settings | Profile info, preferences, sign out |

---

## Project structure

```
lib/
├── main.dart                    # App entry point and auth routing (AuthGate)
├── firebase_options.dart        # Firebase project config
├── models/
│   ├── listing.dart             # Listing data model + Firestore serialization
│   └── user_profile.dart        # User profile model
├── services/
│   ├── auth_service.dart        # Firebase Auth operations + user Firestore doc
│   └── listing_service.dart     # Firestore CRUD and real-time streams
├── providers/
│   ├── auth_provider.dart       # Auth state management (ChangeNotifier)
│   └── listing_provider.dart    # Listing state, filters, location, ratings
├── screens/
│   ├── auth/                    # Login, sign up, verify email
│   ├── home/                    # Main scaffold with bottom navigation
│   ├── directory/               # Browse and search listings
│   ├── my_listings/             # User listings list + create/edit form
│   ├── detail/                  # Listing detail page with map
│   ├── map_view/                # Full-screen map with all listing markers
│   └── settings/                # User settings and sign out
└── widgets/
    ├── listing_card.dart        # Card component used in list views
    └── category_chip.dart       # Category filter chip with live count badge
```

---

## State management

This app uses the **Provider** pattern with a dedicated service layer between Firebase and the UI. Screens never call Firestore directly — they go through providers, which delegate to services.

```
Firestore
   ↓
Services       →  raw Firebase access, stream creation, CRUD
   ↓
Providers      →  business logic, filtering, loading/error states
   ↓
Screens        →  context.watch() to read state, context.read() to trigger actions
```

**AuthProvider** manages the signed-in user, their Firestore profile, and an `AuthStatus` enum (`idle`, `loading`, `error`). It subscribes to Firebase's `authStateChanges` stream on initialization.

**ListingProvider** keeps two separate real-time streams running — one for all listings and one for the current user's listings. A `_filtered()` method applies the active search query and category selection together before the directory screen renders anything. Location fetching via Geolocator is also handled here so distance calculations can run without touching the UI layer.

---

## Database schema

```
Firestore project: kigali_directory

users/
  {uid}/
    uid          : string
    email        : string
    displayName  : string
    createdAt    : string (ISO 8601)

listings/
  {docId}/
    name         : string
    category     : string
    address      : string
    contact      : string
    description  : string
    latitude     : number   (defaults to -1.9441 if not provided)
    longitude    : number   (defaults to 30.0619 if not provided)
    createdBy    : string   (uid of whoever created the listing)
    timestamp    : Timestamp
    rating       : number   (running average, 0.0 – 5.0)
    ratingCount  : number
```

**Categories:** Hospital, Restaurant, School, Bank, Hotel, Market, Pharmacy, Government Office, Transport Hub, Place of Worship, Other

---

## Dependencies

| Package | Used for |
|---|---|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | Real-time cloud database |
| `provider` | State management |
| `google_maps_flutter` | Embedded maps and markers |
| `geolocator` | Device GPS and permission handling |
| `geocoding` | Address ↔ coordinates conversion |
| `url_launcher` | Opening Google Maps and the phone dialer |
| `shared_preferences` | Persisting local settings |
| `cupertino_icons` | iOS-style icon support |

---

## Getting started

### Prerequisites

- Flutter SDK 3.x or later
- A Firebase project with Firestore and Authentication set up
- A Google Maps API key (Maps SDK for Android and/or iOS enabled)

### 1. Clone and install

```bash
git clone <repo-url>
cd kigali_directory
flutter pub get
```

### 2. Connect Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pick your Firebase project when prompted. This regenerates `firebase_options.dart` with your credentials.

In the Firebase Console:
- Enable **Email/Password** sign-in under Authentication → Sign-in method
- Create a **Firestore** database (test mode is fine for development)

### 3. Add your Google Maps API key

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS** — `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### 4. Run

```bash
flutter run
```

This is a mobile-only app. Web and desktop targets are out of scope.

```bash
flutter run -d android   # or pick a device from the list
flutter run -d ios
```

---

## Firestore security rules

These rules let authenticated users read all listings and only modify their own:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.createdBy;
    }
  }
}
```

---

## A few things worth knowing

- **Email verification is enforced at the routing level.** The `AuthGate` in `main.dart` holds unverified users on the verify screen until they confirm their email. There's a resend button if they don't get the email.
- **Default coordinates** fall back to Kigali city center (`-1.9441, 30.0619`) if you leave the lat/long fields empty in the listing form.
- **Ratings** store a running average — each new rating updates both `rating` and `ratingCount` in a single write so the average stays accurate.
- **Location permission** is requested once when the directory loads. If denied, the app still works fine — distances just won't show.
- **Real-time sync** means any listing created, edited, or deleted by any user updates immediately on all other connected devices without a manual refresh.
