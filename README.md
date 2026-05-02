# OneStopSolutions — Unified Android App

A single Flutter Android app that combines the **OSS** (Staff Management), **OSD** (Shop Operations), and **FoodHut** (Food Hut Management) apps into one cohesive application.

## 📱 Features

### 👥 Staff & HR Module (from OSS)
- Mark daily attendance (check-in / not working)
- View personal attendance history
- View salary details & monthly breakdown
- Submit Idea of the Week
- Log improvements
- Admin: Full attendance + salary reports
- SUPERADMIN: All users management, audit logs, summaries

### 🏪 Shop Operations Module (from OSD)
- Live cash balances for Cafe, Bookshop, Food Hut
- Per-shop daily transaction entry (sales + expenses)
- Credits (customer IOU) management
- Bank deposits tracking
- Business overview with P&L analytics
- Expense type management

### 🍽️ Food Hut Kitchen Module (from FoodHut)
- Daily prepared/remaining item entry
- Auto-calculated sold quantities
- Date browsing (historical records)
- Menu item management
- SUPERADMIN business analytics

## 🏗️ Project Structure

```
lib/
├── main.dart                         # App entry & splash gate
├── core/
│   ├── constants/
│   │   └── api_constants.dart        # All API endpoints
│   ├── network/
│   │   └── api_client.dart           # HTTP client with JWT 
│   └── theme/
│       └── app_theme.dart            # Unified brand theme
├── features/
│   ├── auth/
│   │   ├── models/user_model.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   └── pin_service.dart
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── pin_screen.dart
│   ├── staff/
│   │   ├── services/attendance_service.dart
│   │   └── screens/
│   │       ├── attendance_screen.dart
│   │       ├── salary_screen.dart
│   │       ├── all_users_screen.dart
│   │       ├── ideas_screen.dart
│   │       ├── improvements_screen.dart
│   │       └── attendance_report_screen.dart
│   ├── shop/
│   │   ├── services/shop_service.dart
│   │   └── screens/
│   │       ├── shop_detail_screen.dart
│   │       ├── credits_screen.dart
│   │       ├── bank_deposits_screen.dart
│   │       ├── expense_types_screen.dart
│   │       └── business_overview_screen.dart
│   ├── foodhut/
│   │   ├── services/foodhut_service.dart
│   │   └── screens/foodhut_main_screen.dart
│   └── admin/
│       └── screens/audit_logs_screen.dart
└── home/
    └── home_screen.dart               # Main navigation hub
```

## ⚙️ Setup

### 1. Configure API URL

Edit `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8080';
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run

```bash
flutter run
```

### 4. Build APK

```bash
flutter build apk --release
```

## 🔑 Authentication Flow

1. App opens → checks if JWT token exists
2. If no token → Login screen
3. After login → PIN setup (first time) or PIN verify
4. PIN verified → Home screen with role-based modules

## 👥 Role-Based Access

| Role | Staff Module | Shop Ops | Food Hut | Admin |
|------|:---:|:---:|:---:|:---:|
| STAFF | Read-only | View | Record | ❌ |
| ADMIN | Edit | Full | Full | Reports |
| SUPERADMIN | Full | Full | Full | Full |

## 🔧 Backend

Uses the same **OneStopSolutions Spring Boot backend** at port 8080.

See `../backend/` for backend setup.

