# OneStopSolutions Flutter App — Documentation

**Technology:** Flutter · Dart · SharedPreferences · HTTP  
**Platform:** Android (primary) · iOS  
**App Name:** OneStopSolutions  
**Package:** `onestopsolutions`  
**Location:** `C:\dev\oss\onestopsolutions`  
**Backend:** `http://74.208.132.78` → `https://www.onestopdaily.shop` (when HTTPS ready)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [Project Structure](#3-project-structure)
4. [Authentication & Session](#4-authentication--session)
5. [Role System](#5-role-system)
6. [Screens & Features](#6-screens--features)
7. [Services & API](#7-services--api)
8. [Navigation Flow](#8-navigation-flow)
9. [Build & Release](#9-build--release)
10. [Configuration](#10-configuration)

---

## 1. Overview

**OneStopSolutions** is the **staff-facing Flutter mobile app** for the OneStopSolutions business. It is primarily used by staff and admin for:

- **Attendance** — daily check-in / check-out
- **Salary** — viewing monthly pay breakdown
- **Credits** — tracking salary advances / deductions
- **Shops** — viewing and managing daily cash (OSD features)
- **Ideas & Improvements** — staff feedback submission
- **Admin tools** — attendance adjustment, user management (ADMIN/SUPERADMIN)

> This app is intended for **internal staff use only** — employees and managers. Customers do not use this app.

---

## 2. Tech Stack & Dependencies

| Package | Purpose |
|---------|---------|
| `flutter/material.dart` | UI framework |
| `http` | HTTP client for API calls |
| `shared_preferences` | Local session persistence (token, user data) |

### Key Constants
- **API Base URL:** `http://74.208.132.78` (defined in `lib/core/constants/api_constants.dart`)
- **Session storage:** SharedPreferences (token, email, name, role, userId)

---

## 3. Project Structure

```
onestopsolutions/lib/
├── main.dart                          # App entry point, SplashGate routing
├── core/
│   ├── constants/
│   │   └── api_constants.dart         # Base URL + all API endpoint paths
│   ├── network/
│   │   └── api_client.dart            # HTTP client wrapper (GET, POST, PUT, DELETE)
│   └── theme/
│       └── app_theme.dart             # App colors, fonts, theme
├── features/
│   ├── auth/
│   │   ├── models/user_model.dart     # AppUser model (id, name, email, role)
│   │   ├── screens/
│   │   │   ├── login_screen.dart      # Email + password login
│   │   │   ├── register_screen.dart   # Self-registration (CUSTOMER only)
│   │   │   └── pin_screen.dart        # 4-digit PIN setup/verify
│   │   └── services/
│   │       ├── auth_service.dart      # Login, register, session management
│   │       └── pin_service.dart       # PIN save/verify, session validity
│   ├── shop/
│   │   ├── screens/
│   │   │   ├── shop_detail_screen.dart     # Daily cash management per shop
│   │   │   ├── credits_screen.dart          # Credits management
│   │   │   ├── expense_types_screen.dart    # Expense category management
│   │   │   ├── business_overview_screen.dart # Business summary (SUPERADMIN)
│   │   │   └── bank_deposits_screen.dart    # Bank deposit tracking (SUPERADMIN)
│   │   └── services/                        # Shop, credit, expense API services
│   ├── staff/
│   │   ├── screens/
│   │   │   ├── attendance_screen.dart       # Daily check-in / check-out
│   │   │   ├── salary_screen.dart           # Monthly salary view
│   │   │   ├── ideas_screen.dart            # Submit ideas of the week
│   │   │   ├── improvements_screen.dart     # Submit improvement suggestions
│   │   │   ├── all_users_screen.dart        # User list (ADMIN+)
│   │   │   ├── attendance_report_screen.dart # Attendance reports (ADMIN+)
│   │   │   ├── staff_performance_screen.dart # Performance dashboard (SUPERADMIN)
│   │   │   └── user_attendance_editor_screen.dart # Edit staff attendance (SUPERADMIN)
│   │   └── services/
│   ├── admin/
│   │   └── screens/                         # Admin-only management screens
│   ├── foodhut/
│   │   └── screens/                         # Food Hut POS screens
│   └── home/
│       └── screens/
│           └── home_screen.dart             # Main menu / navigation hub
```

---

## 4. Authentication & Session

### Login Flow

```
App Launch
    │
    ├── isLoggedIn? ─── NO ──→ LoginScreen
    │                              │
    │                              ↓ Email + Password
    │                         POST /api/auth/login
    │                              │
    │                         ✅ 200 OK → Save session → PinScreen (setup)
    │                         ❌ 401 → Show error
    │
    ├── isLoggedIn? ── YES ──→ hasPinSet?
    │                              │
    │                         NO ──→ PinScreen (isSetup: true)
    │                         YES ──→ isSessionValid?
    │                                      │
    │                                 NO ──→ LoginScreen
    │                                 YES ──→ PinScreen (isSetup: false) → HomeScreen
```

### Session Storage (SharedPreferences)

| Key | Type | Value |
|-----|------|-------|
| `token` | String | JWT Bearer token |
| `email` | String | User's email address |
| `name` | String | User's display name |
| `role` | String | `STAFF`, `ADMIN`, `SUPERADMIN`, `CUSTOMER` |
| `userId` | Int | Numeric user ID |
| `user_pin` | String | 4-digit PIN (stored locally only) |
| `session_start` | Int | Epoch ms when PIN was set — used for 3-day session validity |

### Session Validity

PIN sessions are valid for **3 days**. After expiry:
- User is redirected to `LoginScreen`
- Must re-enter email + password
- Must set a new PIN

### AuthService Methods

| Method | Description |
|--------|-------------|
| `login(email, password)` | POST to `/api/auth/login`, saves session |
| `register(name, email, password)` | POST to `/api/auth/register` with `role: 'CUSTOMER'` |
| `logout()` | Removes all session keys from SharedPreferences |
| `isLoggedIn()` | Checks if token exists and is non-empty |
| `getCurrentUser()` | Reads user from SharedPreferences → returns `AppUser` |
| `getToken()` | Returns stored JWT token |
| `getRole()` | Returns stored role string |

### PinService Methods

| Method | Description |
|--------|-------------|
| `savePin(pin)` | Saves PIN locally + records session start time |
| `verifyPin(pin)` | Compares entered PIN with stored PIN |
| `hasPinSet()` | Checks if `user_pin` key exists |
| `isSessionValid()` | Checks if session is within 3 days |
| `clearSession()` | Removes token, PIN, session start, user data |
| `refreshSession()` | Updates session_start to now (extends session) |

---

## 5. Role System

The app reads the `role` from SharedPreferences after login and controls feature visibility based on it.

| Role | Who Uses It | Access Level |
|------|------------|--------------|
| `CUSTOMER` | Self-registered users | View own data only — not intended for this app |
| `STAFF` | Shop employees | Attendance, salary, ideas, view shop data |
| `ADMIN` | Shop managers | Full shop management + staff reports |
| `SUPERADMIN` | Owner / system admin | Everything including business overview, user management |

### Feature Access by Role

| Feature | STAFF | ADMIN | SUPERADMIN |
|---------|-------|-------|------------|
| Check in/out attendance | ✅ | ✅ | ✅ |
| View own salary | ✅ | ✅ | ✅ |
| Submit ideas/improvements | ✅ | ✅ | ✅ |
| View shop daily data | ✅ | ✅ | ✅ |
| Add expenses/sales/credits | ❌ | ✅ | ✅ |
| View all users | ❌ | ✅ | ✅ |
| View attendance reports | ❌ | ✅ | ✅ |
| Edit attendance adjustments | ❌ | ✅ | ✅ |
| Edit/delete transactions | ❌ | ❌ | ✅ |
| Edit/delete credits | ❌ | ❌ | ✅ |
| Business overview | ❌ | ❌ | ✅ |
| Bank deposits view | ❌ | ❌ | ✅ |
| Staff performance report | ❌ | ❌ | ✅ |
| User management | ❌ | ❌ | ✅ |

---

## 6. Screens & Features

### Auth Screens

#### LoginScreen (`features/auth/screens/login_screen.dart`)
- Email + password fields
- Calls `AuthService.login()` → on success navigates to PinScreen (setup)
- Link to RegisterScreen

#### RegisterScreen (`features/auth/screens/register_screen.dart`)
- Name, email, password fields
- Registers as **CUSTOMER only** (role hardcoded, dropdown removed)
- No role selection — security measure to prevent self-elevation
- On success, navigates back to LoginScreen

#### PinScreen (`features/auth/screens/pin_screen.dart`)
- 4-digit numeric keypad (custom UI)
- **Setup mode (`isSetup: true`):** Enter PIN → Confirm PIN → saved locally → go to HomeScreen
- **Verify mode (`isSetup: false`):** Enter PIN → compare with stored → go to HomeScreen
- Shake animation on incorrect PIN
- Logout button (verify mode only) — clears session → LoginScreen

---

### Staff Screens

#### AttendanceScreen
- Shows today's status (WORKING / NOT_WORKING / not started)
- **YES** button → `POST /api/attendance/working` → marks as working (check-in)
- **NO** button → `POST /api/attendance/not-working` → marks as not working
- Shows check-in time, hours worked
- History tab: past attendance records

#### SalaryScreen
- Month/year picker (defaults to current month)
- Shows: base salary, overtime, deductions, credits, net pay
- Breakdown of how salary is calculated

#### IdeasScreen
- Input field to submit weekly idea
- View past ideas submitted by all staff

#### ImprovementsScreen
- Input field to submit improvement suggestion
- View all improvement submissions

---

### Shop Screens *(ADMIN+ for write operations)*

#### ShopDetailScreen (via Home menu)
- Select shop (Cafe / Bookshop / Food Hut) + date
- View: opening cash, expenses list, sales list, credits, closing cash
- **ADMIN+:** Add expense, add sale, add credit
- **SUPERADMIN:** Edit/delete any transaction, edit/delete credits, override cash amounts

#### CreditsScreen
- Full list of credits across all shops
- Filter by shop, paid/unpaid status
- **ADMIN+:** Add new credit
- **SUPERADMIN:** Mark as paid, edit, delete

#### ExpenseTypesScreen *(ADMIN+)*
- View all expense categories
- Add new expense type by shop
- SUPERADMIN: delete expense types

#### BusinessOverviewScreen *(SUPERADMIN only)*
- Monthly aggregate view: total sales, total expenses, cash on hand, unpaid credits
- Per-shop breakdown
- Top expense categories

#### BankDepositsScreen *(SUPERADMIN only)*
- View all bank deposit transactions across shops
- Date range filter

---

### Admin Screens *(ADMIN+)*

#### AllUsersScreen
- List all users with name, email, role
- Navigate to user detail / attendance editor

#### AttendanceReportScreen
- View attendance for all staff
- Filter by date range and user
- Approve/adjust overtime and deduction hours

#### StaffPerformanceScreen *(SUPERADMIN)*
- Staff performance across shops for a date range
- Shows: days worked, total hours, credits

#### UserAttendanceEditorScreen *(SUPERADMIN)*
- Edit any staff member's attendance record
- Change status (WORKING / NOT_WORKING / HALF_DAY / ABSENT)
- Adjust overtime and deduction hours

---

## 7. Services & API

### API Constants (`core/constants/api_constants.dart`)

```dart
static const String baseUrl = 'http://74.208.132.78';

// Auth
static const String login    = '/api/auth/login';
static const String register = '/api/auth/register';

// Attendance
static const String attendanceToday   = '/api/attendance/today';
static const String attendanceCheckIn = '/api/attendance/working';
static const String attendanceCheckOut = '/api/attendance/not-working';
static const String attendanceHistory  = '/api/attendance/history';
static const String attendanceAll      = '/api/attendance/all';

// Salary
static const String salaryMe      = '/api/salary/me/monthly';
static const String salaryAdmin   = '/api/salary/admin/monthly';

// Credits
static const String credits       = '/api/credits';
static const String creditsMe     = '/api/credits/me';
// ... etc
```

### ApiClient (`core/network/api_client.dart`)

Central HTTP wrapper that:
- Attaches `Authorization: Bearer <token>` automatically
- Sets `Content-Type: application/json`
- Returns raw `http.Response`

```dart
ApiClient.get('/api/attendance/today')
ApiClient.post('/api/auth/login', { 'email': ..., 'password': ... })
ApiClient.put('/api/attendance/123', data)
ApiClient.delete('/api/credits/456')
```

### AuthService

Handles login, register, logout, session persistence.  
> See [Section 4](#4-authentication--session) for full method reference.

---

## 8. Navigation Flow

```
SplashGate (main.dart)
    │
    ├── Not logged in ──────────────────────────→ LoginScreen
    │                                                  │
    │                                         ┌────────┴────────┐
    │                                         │                 │
    │                                    RegisterScreen    (login success)
    │                                                           │
    ├── Logged in, no PIN ──────────────────────→ PinScreen (setup)
    │                                                           │
    ├── Logged in, PIN set, session valid ──────→ PinScreen (verify)
    │                                                           │
    └── Logged in, session expired ─────────────→ LoginScreen
                                                               │
                                                          HomeScreen
                                                               │
                            ┌──────────────┬──────────────────┼──────────────────────┐
                            │              │                   │                      │
                     AttendanceScreen  SalaryScreen    ShopDetailScreen      Ideas/Improvements
                            │                                  │
                     (ADMIN+)                           (ADMIN+ features)
                     AttendanceReport              CreditsScreen, ExpenseTypes
                            │
                     (SUPERADMIN)
                     StaffPerformance
                     BusinessOverview
                     BankDeposits
                     UserManagement
```

---

## 9. Build & Release

### Debug Run

```powershell
cd C:\dev\oss\onestopsolutions
flutter run                          # Run on connected device/emulator
flutter run -d <device-id>           # Run on specific device
```

### Release APK

```powershell
flutter build apk --release          # Build release APK
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Install on Device

```powershell
flutter install                      # Install to connected device
# Or manually transfer app-release.apk and install
```

### Check Connected Devices

```powershell
flutter devices
```

### Clean Build

```powershell
flutter clean && flutter pub get && flutter build apk --release
```

---

## 10. Configuration

### API Base URL

File: `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static const String baseUrl = 'http://74.208.132.78';   // ← Change here
  // ...
}
```

**To switch to HTTPS** (when SSL is ready):
```dart
static const String baseUrl = 'https://www.onestopdaily.shop';
```
Then rebuild and redeploy the APK.

### Android Permissions

File: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<application
    android:usesCleartextTraffic="true">   <!-- Required for HTTP (non-HTTPS) -->
```

> ⚠️ `usesCleartextTraffic="true"` must remain until HTTPS is enabled. After switching to HTTPS, this can be removed.

### pubspec.yaml (Key Dependencies)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.x.x              # HTTP client
  shared_preferences: ^2.x.x  # Local session storage
```

---

## Security Notes

| Item | Status | Action |
|------|--------|--------|
| Self-registration defaults to CUSTOMER | ✅ Fixed | `role = 'CUSTOMER'` in `auth_service.dart` |
| No role selector on register screen | ✅ Fixed | Dropdown removed; CUSTOMER only |
| App uses HTTP (not HTTPS) | ⚠️ Pending | Switch `baseUrl` to HTTPS when SSL is ready |
| JWT token stored in SharedPreferences | Acceptable | Standard Flutter practice; tokens expire in 10 years by design |
| PIN stored in SharedPreferences | Acceptable | PIN is a convenience lock, not primary security. JWT is the real auth |

