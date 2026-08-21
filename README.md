# Trabajo Hub — Flutter Mobile App

> **HealthStaff / TrabajHub** nurse-facing mobile application built with Flutter and Riverpod. Connects nurses with open shifts, manages credentials, tracks visits, and facilitates real-time communication with facilities.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Features](#features)
- [Getting Started](#getting-started)
- [Environment & Configuration](#environment--configuration)
- [Authentication & Security](#authentication--security)
- [State Management](#state-management)
- [Navigation](#navigation)
- [API Integration](#api-integration)
- [Key Modules](#key-modules)
    - [Auth](#auth)
    - [Shifts Marketplace](#shifts-marketplace)
    - [My Shifts](#my-shifts)
    - [Calendar](#calendar)
    - [Messaging / Chat](#messaging--chat)
    - [Credentials](#credentials)
    - [Cases](#cases)
    - [Visits](#visits)
    - [Notifications](#notifications)
    - [Profile](#profile)
- [Dependency List](#dependency-list)
- [Scripts & Commands](#scripts--commands)
- [Known Issues & Gotchas](#known-issues--gotchas)
- [Contributing](#contributing)

---

## Overview

TrabajHub is a healthcare staffing platform. This repository contains the **Flutter mobile app** — the primary interface for **nurses** to:

- Browse and book open shifts in a marketplace
- View booked shifts on a map and in a calendar
- Check in and out of visits with GPS verification (EVV)
- Upload and track professional credentials
- Chat in real-time with recruiters and facility staff
- Manage their profile, wallet, and 2FA security

The backend is a Node.js / Express / Prisma / PostgreSQL API. The admin-facing side is a separate Next.js web dashboard (not in this repo).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State management | Riverpod (`flutter_riverpod`) |
| HTTP client | Dio |
| Secure storage | `flutter_secure_storage` |
| Maps | `flutter_map` + OpenStreetMap tiles |
| Calendar | `table_calendar` |
| File picking | `file_picker` |
| Image caching | `fast_cached_network_image` |
| Date formatting | `intl` |
| Backend | Node.js / Express / Prisma / PostgreSQL |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # Colors, gradients, accent color
│   ├── network/
│   │   ├── dio_client.dart             # Singleton Dio instance + provider
│   │   └── dio_interceptor.dart        # Auth token injection
│   ├── storage/
│   │   └── secure_storage.dart         # Access/refresh token persistence
│   ├── utils/
│   │   └── json_utils.dart             # parseDouble / parseInt helpers
│   └── widgets/
│       └── buttons/
│           └── notification_button.dart # NotificationsBell widget
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_api.dart
│   │   │   ├── auth_repository.dart
│   │   │   ├── auth_repository_impl.dart
│   │   │   └── models/
│   │   │       └── user_model.dart      # UserModel, NurseProfileData, WalletSummary, CredentialSummary
│   │   ├── state/
│   │   │   ├── auth_notifier.dart
│   │   │   └── auth_state.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── presentation/
│   │       ├── sign_in.dart
│   │       ├── register.dart
│   │       ├── forgot_password.dart
│   │       ├── reset_password.dart
│   │       ├── verify_email.dart
│   │       ├── profile_screen.dart
│   │       ├── two_fa_verify_screen.dart   # Login 2FA challenge
│   │       └── two_fa_setup_screen.dart    # Enable / disable 2FA from profile
│   │
│   ├── shifts/
│   │   ├── data/
│   │   │   ├── shifts_api.dart
│   │   │   ├── shifts_repository.dart
│   │   │   ├── shifts_repository_impl.dart
│   │   │   └── models/
│   │   │       ├── shift_model.dart
│   │   │       └── shift_assignment_model.dart
│   │   ├── state/
│   │   │   ├── marketplace_state.dart
│   │   │   ├── marketplace_notifier.dart
│   │   │   ├── my_shifts_state.dart
│   │   │   └── my_shifts_notifier.dart
│   │   ├── providers/
│   │   │   └── shifts_provider.dart
│   │   └── presentation/
│   │       ├── marketplace_screen.dart
│   │       ├── my_shifts_screen.dart
│   │       ├── shift_detail_screen.dart
│   │       ├── map_screen.dart             # flutter_map shift pins
│   │       └── widgets/
│   │           ├── shift_card.dart
│   │           └── my_shift_card.dart
│   │
│   ├── calendar/
│   │   ├── data/
│   │   │   ├── calendar_api.dart
│   │   │   ├── calendar_repository.dart
│   │   │   ├── calendar_repository_impl.dart
│   │   │   └── models/
│   │   │       └── calendar_event_model.dart
│   │   ├── state/
│   │   │   ├── calendar_state.dart
│   │   │   └── calendar_notifier.dart
│   │   ├── providers/
│   │   │   └── calendar_provider.dart
│   │   └── presentation/
│   │       ├── calendar_screen.dart
│   │       └── widgets/
│   │           ├── event_type_filter_bar.dart
│   │           ├── calendar_event_dot.dart
│   │           └── event_detail_sheet.dart
│   │
│   ├── messaging/
│   │   ├── data/
│   │   │   ├── messaging_api.dart
│   │   │   ├── messaging_repository.dart
│   │   │   ├── messaging_repository_impl.dart
│   │   │   └── models/
│   │   │       ├── conversation_model.dart
│   │   │       └── message_model.dart
│   │   ├── state/
│   │   │   ├── messaging_state.dart
│   │   │   └── messaging_notifier.dart
│   │   ├── providers/
│   │   │   └── messaging_provider.dart
│   │   └── presentation/
│   │       ├── conversations_screen.dart   # Conversation list
│   │       ├── chat_detail_screen.dart     # Individual chat thread
│   │       └── widgets/
│   │           ├── conversation_tile.dart
│   │           └── message_bubble.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   ├── notifications_api.dart
│   │   │   ├── notifications_repository.dart
│   │   │   ├── notifications_repository_impl.dart
│   │   │   └── models/
│   │   │       └── notification_model.dart
│   │   ├── state/
│   │   │   ├── notifications_state.dart
│   │   │   └── notifications_notifier.dart
│   │   ├── providers/
│   │   │   └── notifications_provider.dart
│   │   └── presentation/
│   │       ├── notifications_screen.dart
│   │       └── widgets/
│   │           └── notification_tile.dart
│   │
│   ├── credentials/
│   │   ├── data/ ...
│   │   ├── state/ ...
│   │   ├── providers/ ...
│   │   └── presentation/
│   │       ├── credentials_screen.dart
│   │       └── widgets/
│   │           └── upload_credential_sheet.dart
│   │
│   ├── cases/
│   │   ├── data/ ...
│   │   ├── state/ ...
│   │   ├── providers/ ...
│   │   └── presentation/
│   │       ├── cases_screen.dart
│   │       └── case_detail_screen.dart
│   │
│   └── visits/
│       ├── data/ ...
│       ├── state/ ...
│       ├── providers/ ...
│       └── presentation/
│           ├── visits_screen.dart
│           └── visit_detail_screen.dart
│
├── routes/
│   └── app_router.dart
│
└── main.dart
```

---

## Architecture

Every feature follows a strict **5-layer architecture**:

```
API  →  Repository  →  State (Notifier + State class)  →  Provider  →  Presentation
```

| Layer | Responsibility |
|---|---|
| `*_api.dart` | Raw Dio calls — returns `Map<String, dynamic>` |
| `*_repository.dart` | Abstract interface |
| `*_repository_impl.dart` | Parses API response into typed models, calls API layer |
| `*_notifier.dart` | Business logic, state transitions, calls repository |
| `*_state.dart` | Immutable state class with `copyWith` |
| `*_provider.dart` | Riverpod `Provider` / `StateNotifierProvider` wiring |
| `presentation/` | Widgets — read state via `ref.watch`, dispatch via `ref.read` |

### Design decisions

- **No direct Dio calls from UI** — always goes through the repository layer.
- **Optimistic updates** — e.g. marking a notification read updates local state immediately, rolls back on error.
- **`_sentinel` pattern** — used in `copyWith` to differentiate `null` (clear a value) from "not provided" (keep existing).
- **Decimal fields** — Prisma serialises `Decimal` columns as strings. All monetary/numeric fields use `parseDouble(json['field'])` from `core/utils/json_utils.dart` rather than a direct `as num?` cast.

---

## Features

### Nurse-facing screens

| Screen | Description |
|---|---|
| Sign In | Email/password login with 2FA challenge support |
| Register | Role-based registration (NURSE only on mobile) |
| Email Verification | OTP verification after registration |
| Marketplace | Browse open shifts with search, filters, and urgency flags |
| Shift Map | OpenStreetMap view of shift locations with tap-to-preview cards |
| My Shifts | Tabbed list of upcoming, completed, and cancelled assignments |
| Shift Detail | Full shift info with instant-book button |
| Calendar | Month/week view with colour-coded event dots and detail sheets |
| Messaging | Conversation list + individual chat with file attachment support |
| Notifications | Bell badge, unread filter, tap-to-navigate by notification type |
| Credentials | Upload, view, and delete professional documents |
| Cases | Browse assigned cases with detail view |
| Visits | Visit history with check-in/out times, distances, and audit trail |
| Profile | Edit personal info, change password, enable/disable 2FA |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio / Xcode (for device/emulator)
- A running instance of the TrabajHub backend API

### 1. Clone the repository

```bash
git clone https://github.com/your-org/trabajo-hub-mobile.git
cd trabajo-hub-mobile
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the API base URL

Open `lib/core/network/dio_client.dart` and update `baseUrl`:

```dart
BaseOptions(
  baseUrl: 'http://YOUR_API_HOST:8000/api/v1',
  ...
)
```

For local development on a physical Android device, use your machine's LAN IP (e.g. `http://192.168.1.100:8000/api/v1`) rather than `127.0.0.1`.

### 4. Android — allow cleartext (dev only)

If your local API runs over HTTP, add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application
  android:usesCleartextTraffic="true"
  ...>
```

> Remove this before a production build.

### 5. Run the app

```bash
# Debug on connected device / emulator
flutter run

# Release build (Android)
flutter build apk --release

# Release build (iOS)
flutter build ipa --release
```

---

## Environment & Configuration

### `lib/core/constants/app_constants.dart`

Global design tokens used throughout the app:

```dart
class ColorConstants {
  static const appGradient = LinearGradient(
    colors: [Color(0xff0a9fbf), Color(0xff28d744)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

Color accentColor = Color(0XFF007AFF);
Color dark       = Color(0XFF536C79);
```

### `lib/core/network/dio_client.dart`

- Single static `Dio` instance shared across all API classes.
- `AuthInterceptor` injects `Authorization: Bearer <token>` on every request by reading from `AppStorage`.
- SSL certificate validation is relaxed for local development via `IOHttpClientAdapter` — **remove before production**.
- Expose the static instance to providers via the instance getter `DioClient().instance`.

### `lib/core/storage/secure_storage.dart`

Wraps `flutter_secure_storage`. Stores and retrieves:

- `accessToken`
- `refreshToken`

Tokens are injected per-request by `AuthInterceptor` and rotated on every call to `POST /auth/refresh`.

---

## Authentication & Security

### Login flow

```
SignInScreen
  → AuthNotifier.login()
      → AuthRepositoryImpl.login()
          → POST /auth/login
  ← { user, accessToken, refreshToken }         # normal login
  ← { requires2FA, userId, challengeToken }      # 2FA required
      → navigate to TwoFAVerifyScreen
          → AuthNotifier.verify2FA(totpCode)
              → POST /auth/2fa/verify
          ← { user, accessToken, refreshToken }
      → navigate to NurseHomeShell
```

### Token refresh

`AuthRepositoryImpl.refreshSession()` calls `POST /auth/refresh` and overwrites both tokens in secure storage. This is called from `AuthNotifier.initializeAuth()` on app start and can be called from a Dio response interceptor for automatic renewal.

### Two-factor authentication (TOTP)

| Action | Screen | Backend endpoint |
|---|---|---|
| Enable 2FA | `TwoFASetupScreen` | `POST /auth/2fa/setup` → `POST /auth/2fa/enable` |
| Login challenge | `TwoFAVerifyScreen` | `POST /auth/2fa/verify` |
| Disable 2FA | `Disable2FASheet` | `PATCH /auth/2fa/disable` |

The setup screen fetches a QR code data URL from the backend and displays it via `Image.memory(base64Decode(...))`. After scanning, the user confirms with their first TOTP code to activate.

---

## State Management

The app uses **Riverpod** with `StateNotifier` throughout.

### Provider naming convention

| Provider | Type | Purpose |
|---|---|---|
| `authProvider` | `StateNotifierProvider` | Auth state — user, loading, error, 2FA challenge |
| `currentUserProvider` | `Provider` | Derived — `ref.watch(authProvider).user` |
| `marketplaceProvider` | `StateNotifierProvider` | Open shifts list + booking |
| `myShiftsProvider` | `StateNotifierProvider` | Nurse's assignments |
| `calendarProvider` | `StateNotifierProvider` | Calendar events by day |
| `messagingProvider` | `StateNotifierProvider` | Conversations + messages + polling |
| `notificationsProvider` | `StateNotifierProvider` | Notifications list + unread count |
| `unreadCountProvider` | `Provider` | Derived unread badge count |
| `credentialsProvider` | `StateNotifierProvider` | Credential list + upload/delete |
| `casesProvider` | `StateNotifierProvider` | Case list + search |
| `visitsProvider` | `StateNotifierProvider` | Visit history |
| `shiftDetailProvider` | `FutureProvider.family` | Single shift detail (auto-disposed) |
| `caseDetailProvider` | `FutureProvider.family` | Single case detail |
| `visitDetailProvider` | `FutureProvider.family` | Single visit detail |

### State pattern

Every state class follows this shape:

```dart
class ExampleState {
  final ExampleStatus status;   // enum: initial / loading / success / error
  final List<ExampleModel> items;
  final bool hasMore;
  final int page;
  final String? errorMessage;

  ExampleState copyWith({ ... }); // uses _sentinel for nullable fields
}
```

`_sentinel` is a private `const Object()` used in `copyWith` to distinguish "not provided" from an intentional `null`, enabling `copyWith(errorMessage: null)` to actually clear the field.

---

## Navigation

Navigation is imperative (`Navigator.push` / `Navigator.pop`) with named routes for the root scaffold. The main nurse shell uses a `NavigationBar` (Material 3) with tabs for:

1. **Marketplace** — `MarketplaceScreen`
2. **My Shifts** — `MyShiftsScreen`
3. **Calendar** — `CalendarScreen`
4. **Messages** — `ConversationsScreen`
5. **Profile** — `ProfileScreen`

Notifications are reachable from the `NotificationsBell` widget in any screen's header.

### Deep-linking from notifications

`NotificationsScreen` uses an exhaustive `switch` on `NotificationType` to route taps:

```
newMessage            → ConversationsScreen
shiftAlert
assignmentUpdate
shiftCancelled        → MyShiftsScreen
bookingConfirmation
credentialExpiry
paymentAlert          → ProfileScreen
credentialApproved
credentialRejected
systemAlert
```

---

## API Integration

### Base URL

Configured in `DioClient._createDio()`. All paths are relative to `/api/v1`.

### Request / response envelope

Every backend response follows:

```json
{
  "success": true,
  "message": "...",
  "data": { ... },
  "pagination": { "page": 1, "limit": 20, "total": 45, "hasNext": true, "hasPrev": false }
}
```

Repository implementations always read `raw['data']` and `raw['pagination']`.

### Decimal / numeric fields

Prisma serialises `Decimal` DB columns as JSON strings (e.g. `"42.50"`). Use the shared helper instead of direct casts:

```dart
// lib/core/utils/json_utils.dart
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
```

Affected fields: `payRate`, `chargeRate`, `pendingBalance`, `availableBalance`, `lifetimeEarnings`, `total`, `checkInDistance`.

### Authentication headers

`AuthInterceptor.onRequest` reads the access token from `AppStorage` and sets:

```
Authorization: Bearer <accessToken>
```

---

## Key Modules

### Auth

**Files:** `features/auth/`

Handles the complete authentication lifecycle:

- `register` → returns `userId` for email verification screen
- `verifyEmail` / `resendVerification` → OTP flow
- `login` → throws `TwoFactorRequiredException` when 2FA challenge needed
- `verify2FA` → completes challenge, saves tokens
- `fetchMe` → hydrates full `UserModel` including `NurseProfileData`, `WalletSummary`, and `CredentialSummary[]`
- `updateProfile` / `changePassword` → profile mutations followed by `fetchMe`
- `setup2FA` / `enable2FA` / `disable2FA` → TOTP management
- `initializeAuth()` → called on app start; fetches `/users/me` if a token exists

`UserModel` includes nested models: `NurseProfileData` → `WalletSummary` + `CredentialSummary[]`.

---

### Shifts Marketplace

**Files:** `features/shifts/presentation/marketplace_screen.dart`

- Loads open shifts matching the nurse's designation via `GET /shifts/marketplace`
- Filter chips: visit type (REGULAR, ADMISSION, etc.) and urgency flag
- **Search**: debounced 400ms text input wired to `search` query param
- Infinite scroll: loads next page when within 200px of the bottom
- **Book now**: atomic booking via `POST /shifts/:id/book` — removes booked shift from list on success
- **Map view** FAB: opens `ShiftMapScreen` with all shifts that have coordinates

---

### My Shifts

**Files:** `features/shifts/presentation/my_shifts_screen.dart`

- Tabbed view: Upcoming (ACCEPTED) / Completed / Cancelled
- Switching tabs resets pagination and reloads
- Cancel button shows confirmation dialog before calling `PATCH /shifts/:id/cancel`
- Tapping a card navigates to `ShiftDetailScreen`

---

### Calendar

**Files:** `features/calendar/`

Uses `table_calendar` with a custom marker builder that renders coloured dots per event type. Event types:

| Type | Colour |
|---|---|
| SHIFT | Blue |
| RECURRING_SHIFT | Purple |
| VISIT | Green |
| CREDENTIAL_EXPIRY | Red |
| INVOICE_DUE | Amber |
| INVOICE_OVERDUE | Rose |

Tapping an event list tile opens `EventDetailSheet` — a `DraggableScrollableSheet` with structured field rows per event type (shift, visit, credential, invoice).

The calendar reloads when the user navigates to a new month via `onPageChanged`. Filter toggles re-trigger the load with updated type params.

---

### Messaging / Chat

**Files:** `features/messaging/`

Split into two screens:

- **`ConversationsScreen`** — list of conversations with unread badge, new conversation sheet (user search + start)
- **`ChatDetailScreen`** — message thread with send, file attachment, delete, and mark-read

**Polling**: `MessagingNotifier.startPolling()` sets a 30-second `Timer.periodic` that refreshes conversations and the active thread silently. Called from `ConversationsScreen.initState`, stopped in `dispose`.

**New conversation**: debounced user search (`GET /users/chat?search=...`) with a `ConstrainedBox` dropdown. Selecting a user enables the Start button which calls `POST /messages/conversations`.

**File attachment**: uses `file_picker` to select a file, then sends `multipart/form-data` to `POST /messages/conversations/:id/attachments`.

---

### Credentials

**Files:** `features/credentials/`

- Lists nurse's own credentials with status colour coding (Pending/Approved/Rejected/Expired)
- Upload sheet: type dropdown, custom label (for CUSTOM type), issued/expiry date pickers, file picker (PDF, JPG, PNG)
- File is sent as `multipart/form-data` to `POST /credentials`
- Delete is only enabled for non-approved credentials

---

### Cases

**Files:** `features/cases/`

- Paginated list with debounced search (`publicIdentifier`, patient name)
- Visit type filter chips
- Detail screen shows case address, clinical info (masked for nurses), and recent shifts with assignee names

---

### Visits

**Files:** `features/visits/`

- Visit history scoped automatically to the current nurse by the backend
- Status filter chips and a "Flagged" toggle
- Detail screen shows check-in/out times, GPS distances, override alerts, notes, and full audit trail timeline

---

### Notifications

**Files:** `features/notifications/`

- `NotificationsBell` widget reads `unreadCountProvider` for the badge — drop it into any header's `Row`
- `NotificationsScreen` has All / Unread filter tabs
- Mark one read: optimistic update (local state first, API call second, rollback on failure)
- Mark all read: single `PATCH /notifications/read-all` call
- Infinite scroll for older notifications

---

### Profile

**Files:** `features/auth/presentation/profile_screen.dart`

Sections:
- **Avatar** — initials from `NurseProfileData.fullName` or network image if `avatarUrl` is set
- **Wallet card** — available, pending, and lifetime earnings
- **Credentials summary** — count per status with expiry warnings
- **Account info** — email, phone, location, years of experience, availability
- **Security** — change password sheet + 2FA toggle (enable via `TwoFASetupScreen`, disable via `Disable2FASheet`)
- **Logout** — clears secure storage and resets `AuthState`

---

## Dependency List

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  dio: ^5.x
  flutter_secure_storage: ^9.x
  fast_cached_network_image: ^1.x
  flutter_map: ^7.x
  latlong2: ^0.9.x
  table_calendar: ^3.x
  file_picker: ^8.x
  intl: ^0.19.x
```

Add to `pubspec.yaml` as needed — versions above are minimums tested during development.

---

## Scripts & Commands

```bash
# Get packages
flutter pub get

# Run on device (debug)
flutter run

# Run with specific flavor / device
flutter run -d <device-id>

# Analyze code
flutter analyze

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build iOS IPA
flutter build ipa --release

# Clean build artifacts
flutter clean && flutter pub get
```

---

## Known Issues & Gotchas

### Prisma Decimal → String cast crash

Prisma serialises `Decimal` fields as JSON strings. Never use `(json['field'] as num?)` — always use `parseDouble(json['field'])` from `core/utils/json_utils.dart`. Affected fields: `payRate`, `chargeRate`, `pendingBalance`, `availableBalance`, `lifetimeEarnings`.

### DioClient static vs instance

`DioClient.dio` is a static field. Feature API classes receive a `DioClient` instance via Riverpod. Access the Dio object through the instance getter:

```dart
// In DioClient:
Dio get instance => DioClient.dio;

// In feature API:
final response = await _client.instance.get('/path');
```

### SSL handshake on local dev

`IOHttpClientAdapter.createHttpClient` is overridden to allow self-signed certs during local development. **Remove this block before building for production.**

### Android cleartext traffic

If the dev API runs over HTTP, `android:usesCleartextTraffic="true"` must be set in `AndroidManifest.xml`. Remove before release.

### `DateTime.now()` in const constructors

`CalendarState` uses `DateTime? focusedDay` with a default of `DateTime.now()`. This cannot be a `const` constructor — use a regular constructor with a null-coalescing default.

### Messaging polling and `dispose`

`MessagingNotifier` holds a `Timer` for polling. `stopPolling()` must be called in the screen's `dispose`. If navigating away from `ConversationsScreen` while a chat is open in the back stack, polling continues — this is intentional to keep the conversation list fresh.

### 2FA login race condition

After `login()` sets `requires2FA` state, `SignInForm` checks `state.requires2FA` to decide whether to navigate. Because the state update is async, always read state _after_ the `await login(...)` call returns:

```dart
await notifier.login(email, password);
if (!mounted) return;
final authState = ref.read(authProvider);
if (authState.requires2FA) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFAVerifyScreen()));
} else if (authState.isAuthenticated) {
  Navigator.pushReplacementNamed(context, '/home');
}
```

---

## Contributing

1. Fork the repository and create a feature branch: `git checkout -b feature/your-feature`
2. Follow the 5-layer architecture for any new feature
3. Use `parseDouble` / `parseInt` for all JSON numeric fields
4. Add `dispose()` for all `TextEditingController`, `ScrollController`, and `Timer` instances
5. Run `flutter analyze` with zero errors before opening a PR
6. Open a pull request against `main` with a clear description of the change

---

*Built by the TrabajHub engineering team. Backend repo: `trabajo-hub-backend`. Admin dashboard repo: `trabajo-hub-web`.*