# 📋 OneStopSolutions — Master Project Documentation
> **Last Updated:** May 2, 2026  
> **Version:** 1.0  
> **Author:** System Documentation

---

## 📌 Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Backend — Spring Boot API](#3-backend--spring-boot-api)
4. [OSS — Staff Management App](#4-oss--staff-management-app)
5. [OSD — Shop Operations Daily App](#5-osd--shop-operations-daily-app)
6. [FoodHut — Food Hut Management App](#6-foodhut--food-hut-management-app)
7. [Database Schema](#7-database-schema)
8. [API Reference](#8-api-reference)
9. [User Roles & Permissions](#9-user-roles--permissions)
10. [Deployment & Infrastructure](#10-deployment--infrastructure)
11. [Roadmap: OneSolutions Unified App](#11-roadmap-onesolutions-unified-app)
12. [Roadmap: OSS Dashboard (Web)](#12-roadmap-oss-dashboard-web)

---

## 1. System Overview

**OneStopSolutions (OSS)** is a business management platform for a Sri Lanka–based multi-shop business. It includes:

| Component | Type | Purpose |
|---|---|---|
| `backend` | Java Spring Boot REST API | Central server for all data & business logic |
| `oss` | Flutter Android App | Staff management, attendance, salary |
| `osd` | Flutter Android App | Shop daily operations, transactions, credits |
| `foodhut` | Flutter Android App | Food Hut menu & sales management |
| `onestopsolutions` | Flutter Android App *(planned)* | Unified app combining all 3 mobile apps |
| `oss-dashboard` | React Web App *(planned)* | Owner business intelligence dashboard |

**Business Context:**
- **3 Shops:** Cafe, Bookshop, Food Hut
- **Staff Roles:** SUPERADMIN, ADMIN, STAFF, CUSTOMER
- **Currency:** Sri Lankan Rupee (Rs)
- **Timezone:** Asia/Colombo (UTC+5:30)
- **Server:** VPS running at port 8080

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                  CLIENT LAYER                        │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │  OSS App │  │  OSD App │  │   FoodHut App      │ │
│  │ (Staff)  │  │  (Daily) │  │   (Food Hut)       │ │
│  │ Flutter  │  │  Flutter │  │   Flutter          │ │
│  └────┬─────┘  └─────┬────┘  └────────┬───────────┘ │
└───────┼──────────────┼────────────────┼─────────────┘
        │              │                │
        └──────────────┼────────────────┘
                       │ HTTPS (REST/JSON + JWT)
                       ▼
┌──────────────────────────────────────────────────────┐
│             BACKEND LAYER (Port 8080)                │
│                                                      │
│  Spring Boot 3.2.0  |  Java 17  |  JWT Security     │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Auth API │  │ Staff API│  │  Shop/Foodhut API │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │          SQLite Database (WAL Mode)          │    │
│  │   /var/lib/oss/oss.db   |  15 tables         │    │
│  └──────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

---

## 3. Backend — Spring Boot API

### 3.1 Overview

| Property | Value |
|---|---|
| **Framework** | Spring Boot 3.2.0 |
| **Language** | Java 17 |
| **Database** | SQLite 3.42 (WAL mode) |
| **Security** | Spring Security + JWT (jjwt 0.11.5) |
| **ORM** | Spring Data JPA + Hibernate |
| **Port** | 8080 |
| **JAR Location** | `/opt/oss/oss-1.0.0.jar` |
| **DB Location** | `/var/lib/oss/oss.db` |

### 3.2 Key Dependencies

| Dependency | Version | Purpose |
|---|---|---|
| spring-boot-starter-web | 3.2.0 | REST API |
| spring-boot-starter-data-jpa | 3.2.0 | Database ORM |
| spring-boot-starter-security | 3.2.0 | Authentication |
| sqlite-jdbc | 3.42.0.0 | SQLite driver |
| hibernate-community-dialects | 6.1.7 | SQLite Hibernate dialect |
| jjwt-api | 0.11.5 | JWT tokens |
| lombok | (managed) | Boilerplate reduction |
| logback-classic | 1.4.11 | Logging |

### 3.3 Controllers Overview

| Controller | Base URL | Module |
|---|---|---|
| `Common_AuthController` | `/api/auth` | Authentication |
| `Common_UserController` | `/api/users` | User CRUD |
| `OSS_AttendanceController` | `/api/attendance` | Staff Attendance |
| `OSS_IdeaController` | `/api/ideas` | Ideas of Week |
| `OSS_ImprovementController` | `/api/improvements` | Improvement Logs |
| `OSS_SalaryController` | `/api/salary` | Salary Reports |
| `OSD_TransactionController` | `/api/transactions` | Shop Transactions |
| `OSD_CreditController` | `/api/credits` | Shop Credits |
| `OSD_ExpenseTypeController` | `/api/expense-types` | Expense Type Mgmt |
| `DailyCashController` | `/api/daily-cash` | Daily Cash Tracking |
| `Admin_DailyCashController` | `/api/admin/daily-cash` | Admin Cash View |
| `Admin_TransactionController` | `/api/admin/transactions` | Admin Transactions |
| `Foodhut_ItemController` | `/api/items` | FoodHut Menu Items |
| `Foodhut_SaleController` | `/api/sales` | FoodHut Sales |
| `AuditLogController` | `/api/audit-logs` | Audit Trailing |
| `ReportController` | `/api/reports` | Business Reports |
| `MigrationController` | `/api/migration` | Data Migration |

### 3.4 Services Overview

| Service | Responsibility |
|---|---|
| `AuthService` | Registration, login, JWT token generation |
| `UserService` | User CRUD operations |
| `AttendanceService` | Check-in, check-out, history, adjustments |
| `CreditService` | Credit creation, payment tracking |
| `CashTransactionService` | Daily cash flow management |
| `DailyCashService` | Opening/closing balance per shop |
| `DailySummaryService` | Per-shop daily P&L summary |
| `OSD_TransactionService` | Shop income/expense transactions |
| `FoodhutItemService` | Restaurant menu item management |
| `Foodhut_TransactionService` | Food prepared, sold, remaining tracking |
| `ReportService` | Attendance, salary, business reports |
| `SalaryReportService` | Per-staff monthly salary calculation |
| `AuditLogService` | User action audit trailing |
| `DataMigrationService` | Database migration utilities |

### 3.5 Security & Authentication

- **JWT-based stateless authentication**
- Every protected API requires `Authorization: Bearer <token>` header
- Token claims include: email, role, userId
- Role-based access using Spring `@PreAuthorize`

**Login Flow:**
```
POST /api/auth/login
  → validate email + password
  → generate JWT token
  → return: { token, email, name, role, userId }
```

**Register Flow:**
```
POST /api/auth/register
  → validates name, email, password
  → CUSTOMER role: auto-generates email/password if not supplied
  → stores BCrypt-hashed password
  → returns: User object
```

---

## 4. OSS — Staff Management App

### 4.1 Overview

| Property | Value |
|---|---|
| **Package Name** | `OSS` |
| **Description** | OneStopSolutions - Staff Management |
| **Build** | Flutter 3.x, Dart ^3.7.2 |
| **Version** | 1.0.0+1 |
| **Target** | Android |

### 4.2 Purpose

The **OSS App** is used by **company staff** to manage their own attendance, view salary, submit ideas and improvement suggestions, and for administrators to manage all staff records.

### 4.3 Features

#### For All Staff (SUPERADMIN, ADMIN, STAFF)
| Feature | Description |
|---|---|
| **Attendance** | Mark daily attendance (check-in/check-out), view personal history |
| **My Attendance Report** | View own monthly/weekly attendance summary |
| **Salary Details** | View own salary breakdown |
| **Idea of the Week** | Submit weekly business improvement ideas |
| **Improvements** | Log operational improvement suggestions |
| **PIN Lock** | App secured with local PIN after first login |

#### For ADMIN
| Feature | Description |
|---|---|
| **Attendance Report** | View all staff attendance |
| **Staff Salary Report** | View salary for all staff |

#### For SUPERADMIN Only
| Feature | Description |
|---|---|
| **All Users** | View, manage all registered users |
| **Audit Logs** | View all user action logs |
| **Ideas Summary** | View all submitted ideas |
| **Improvements Summary** | View all improvement submissions |
| **API Diagnostic** | Debug API connectivity tool |

### 4.4 Screens

| Screen | Route | Access |
|---|---|---|
| LoginScreen | `/login` | Public |
| RegisterScreen | `/register` | Public |
| PinSetupScreen | `/pin-setup` | Authenticated |
| PinEntryScreen | `/pin-entry` | Authenticated |
| MainMenu | `/main` | All Roles |
| AttendanceScreen | `/attendance` | All |
| SalaryDetailsScreen | `/salary-details` | All |
| MyAttendanceReportScreen | `/my-attendance-report` | All |
| AllUsersScreen | `/all-users` | SUPERADMIN |
| ReportsAttendanceScreen | `/reports-attendance` | ADMIN, SUPERADMIN |
| ReportsSalaryScreen | `/reports-salary` | ADMIN, SUPERADMIN |
| IdeaOfTheWeekScreen | `/idea-of-the-week` | All |
| IdeaOfTheWeekSummaryScreen | `/idea-of-the-week-summary` | SUPERADMIN |
| ImprovementsScreen | `/improvements` | All |
| ImprovementsSummaryScreen | `/improvements-summary` | SUPERADMIN |
| AuditLogsScreen | `/audit-logs` | SUPERADMIN |
| DiagnosticScreen | `/diagnostic` | SUPERADMIN |

### 4.5 Services

| Service | File | Purpose |
|---|---|---|
| AuthService | `auth_services.dart` | Login, register, token management |
| PinStorage | `pin_storage.dart` | Local PIN storage (flutter_secure_storage) |
| SriLankaTime | `sri_lanka_time.dart` | Timezone utility (Asia/Colombo) |

### 4.6 Key Dependencies

| Package | Version | Use |
|---|---|---|
| http | ^1.2.0 | API calls |
| shared_preferences | ^2.2.2 | Auth token storage |
| flutter_secure_storage | ^9.0.0 | PIN & sensitive data |
| geolocator | ^14.0.2 | Location for attendance |
| intl | ^0.20.2 | Date/number formatting |
| timezone | ^0.9.2 | Sri Lanka timezone |
| provider | ^6.0.5 | State management |

---

## 5. OSD — Shop Operations Daily App

### 5.1 Overview

| Property | Value |
|---|---|
| **Package Name** | `OSD` |
| **Description** | OneStopDaily |
| **Build** | Flutter 3.x, Dart ^3.7.2 |
| **Version** | 1.0.0+1 |
| **Target** | Android |

### 5.2 Purpose

The **OSD App** is the daily operations app used to manage **3 shops**: Cafe, Bookshop, and Food Hut. It handles daily cash transactions, expenses, credits (customer IOUs), bank deposits, and business performance analytics.

### 5.3 Features

#### Shop Management
| Feature | Description |
|---|---|
| **3 Shops Overview** | View current cash balance for Cafe, Bookshop, Food Hut |
| **Shop Detail** | Per-shop daily transactions view |
| **Daily Sales Entry** | Record opening balance, sales, closing balance |
| **Expense Entry** | Record per-category expenses against a shop |
| **Transaction Edit/Delete** | SUPERADMIN can modify any transaction |

#### Financial Management
| Feature | Description |
|---|---|
| **Credits Management** | Track customer credit (IOU) records |
| **Add Credit** | Record a new credit against a customer |
| **Unpaid Credits Total** | Real-time unpaid credit balance |
| **Bank Deposits** | Record cash deposited to bank |
| **Business Overview** | Cross-shop P&L analysis |

#### Administration
| Feature | Description |
|---|---|
| **Expense Types** | Add/manage expense categories |
| **Audit Logs** | Full system audit trail |
| **Staff Performance** | Individual staff performance metrics |

### 5.4 Screens

| Screen | Route | Access |
|---|---|---|
| LoginScreen | `/login` | Public |
| RegisterScreen | `/register` | Public |
| PinScreen (Setup) | `/pin-setup` | Authenticated |
| PinScreen (Verify) | `/pin-verify` | Authenticated |
| MainMenu | `/menu` | All Roles |
| ShopDetailScreen | `/shop-detail` | All Roles |
| CreditsScreen | `/credits` | ADMIN, SUPERADMIN |
| AddCreditStandaloneScreen | `/add-credit-standalone` | ADMIN, SUPERADMIN |
| ExpenseTypesScreen | `/expense-types` | ADMIN, SUPERADMIN |
| AuditLogsScreen | `/audit-logs` | SUPERADMIN |
| BankDepositsScreen | `/bank-deposits` | SUPERADMIN |
| MyPerformanceScreen | `/my-performance` | All |
| BusinessOverviewScreen | `/business-overview` | SUPERADMIN |

### 5.5 Menu Dashboard Features

The main menu shows **live balances**:
- ☕ Cafe — current closing balance
- 📚 Bookshop — current closing balance
- 🍽️ Food Hut — current closing balance
- 💳 Credits — total unpaid credits amount

### 5.6 Models

| Model | Key Fields |
|---|---|
| `Shop` | id, code, name |
| `Transaction` | id, department, category (SALE/EXPENSE), amount, openingBalance, closingBalance, businessDate |
| `Credit` | id, user, department, amount, reason, isPaid, createdAt |
| `DailyCash` | id, shopId, businessDate, openingBalance, closingBalance |
| `ExpenseType` | id, name, description |
| `AuditLog` | id, userId, action, entity, entityId, timestamp |
| `User` | id, name, email, role, shopCode |

### 5.7 Profit Margins (Hardcoded)

| Shop | Margin |
|---|---|
| CAFE | 12% |
| BOOKSHOP | 15% |
| FOODHUT | 20% |
| Default | 10% |

### 5.8 Sales Formula

```
Calculated Sales = Closing Balance - Opening Balance + Total Expenses + Total Credits
Profit = Sales × (Profit Margin / 100)
```

### 5.9 Services

| Service | File | Purpose |
|---|---|---|
| AuthService | `auth_services.dart` | JWT login/logout |
| ShopService | `shop_service.dart` | Shop balance, detail fetching |
| CreditService | `credit_service.dart` | Credit management |
| ExpenseTypeService | `expense_type_service.dart` | Expense categories |
| ReportService | `report_service.dart` | Business reports |
| UserService | `user_service.dart` | User management |
| AuditLogService | `audit_log_service.dart` | Audit log fetch |
| ApiAdminService | `api_admin_service.dart` | Admin API utilities |
| PinService | `pin_service.dart` | Session PIN management |

---

## 6. FoodHut — Food Hut Management App

### 6.1 Overview

| Property | Value |
|---|---|
| **Package Name** | `OneStopFoodHut` |
| **Description** | OneStop Food Hut |
| **Build** | Flutter 3.x, Dart ^3.7.2 |
| **Version** | 1.0.0+1 |
| **Target** | Android |

### 6.2 Purpose

The **FoodHut App** is dedicated to managing the **Food Hut restaurant** operations. Staff can log prepared items, track what was sold and what remains at end of day, manage the menu, and SUPERADMIN can view business analytics.

### 6.3 Features

#### Daily Operations
| Feature | Description |
|---|---|
| **Date Switcher** | Browse historical records by day |
| **Prepared Items** | Enter quantity prepared for each menu item |
| **Remaining Items** | Enter end-of-day unsold items |
| **Sold Calculation** | Auto-calculated: Previous Remaining + Prepared − Today's Remaining |
| **Summary Cards** | Real-time Prepared / Sold / Remaining amounts |

#### Menu Management
| Feature | Description |
|---|---|
| **View Menu Items** | List all food items with variations |
| **Add Menu Item** | Create new food item with name + price variations |
| **Item Variations** | Each item has: Full / Half / Budget / etc. variations with price and cost |

#### Sales History
| Feature | Description |
|---|---|
| **Total Sales Screen** | Historical sales summary view |
| **Item Detail Screen** | Drill-down per action type (Prepared/Sold/Remaining) |

#### SUPERADMIN Only
| Feature | Description |
|---|---|
| **Business Overview Dashboard** | Profit/loss analysis for Food Hut |
| **SuperAdmin Dashboard** | Admin-level analytics |

### 6.4 Screens

| Screen | Purpose |
|---|---|
| AppEntryPoint | App splash + auth/PIN check |
| LoginScreen | Email/password login |
| PinEntryScreen | PIN lock screen |
| SetupPinScreen | First-time PIN setup |
| MenuScreen | Main dashboard (prepared/sold/remaining) |
| AddItemScreen | Add prepared or remaining items |
| AddNewItemScreen | Create new menu item + variations |
| ItemDetailScreen | Drill-down item list for any category |
| TotalSalesScreen | Sales history |
| ExpenseReportScreen | Expense overview |
| SuperAdminDashboardScreen | Admin analytics |
| AddDataScreen | Bulk data entry |
| AddExpenseScreen | Add expense entry |

### 6.5 Menu Items (Initial Data)

| Item | Variations |
|---|---|
| 6 RICE - CHICKEN | Full (Rs 800), Half (Rs 600), Budget (Rs 300) |
| 9 KOTTU - CHICKEN | Full (Rs 800), Half (Rs 600), Budget (Rs 300) |
| 1 WADE | Large (Rs 50) |
| 2 PARATA | Normal (Rs 50) |
| 3 VEGETABLE ROTIE | Regular (Rs 80) |
| 4 EGG ROLLS | Regular (Rs 100) |
| RICE & CURRY | Egg & Vegi (Rs 300) |
| 9 KOTTU - EGG | Full (Rs 650), Half (Rs 450) |
| 8 RICE - VEGI | Full (Rs 500), Half (Rs 300) |
| GRAVY | Serve (Rs 50) |
| 5 EGG ROTIE | Egg Rotie (Rs 100) |
| 7 RICE - EGG | Full (Rs 650), Half (Rs 450) |
| OTHER | Item (Rs 1) |

### 6.6 Sold Calculation Logic

```
For each item (key = itemName|variation):
  soldQty = previousDayRemaining + todayPrepared - todayRemaining
  soldAmount = soldQty × price
```

### 6.7 Models

| Model | Key Fields |
|---|---|
| `MenuItem` | id, name, variations |
| `MenuItemVariation` | id, variation, price, cost |
| `FoodHutSale` | saleId, itemName, variation, price, cost, quantity, actionType, transactionTime, recordedBy |
| `TodaySummary` | totalPreparedQty, totalRemainingQty, totalSoldQty |
| `ExpenseModel` | id, amount, expenseType, date |

### 6.8 Services

| Service | File | Purpose |
|---|---|---|
| ApiService | `api_services.dart` | All Food Hut API calls |
| AuthService | `auth_services.dart` | Login/logout/token |
| PinService | `pin_service.dart` | PIN management |

### 6.9 Key Dependencies

| Package | Version | Use |
|---|---|---|
| http | ^1.2.0 | API calls |
| shared_preferences | ^2.2.2 | Token & PIN storage |
| fl_chart | ^0.64.0 | Business charts |
| intl | ^0.19.0 | Date formatting |
| provider | ^6.0.5 | State management |

---

## 7. Database Schema

### Tables (15 total)

#### `users`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | Auto-increment |
| name | VARCHAR | Full name |
| email | VARCHAR UNIQUE | Login email |
| password | VARCHAR | BCrypt hash |
| role | VARCHAR | SUPERADMIN / ADMIN / STAFF / CUSTOMER |
| shop_code | VARCHAR | Optional: CAFE, BOOKSHOP, FOODHUT |
| daily_wage | DECIMAL | Per day salary |
| created_at | DATETIME | Registration date |

#### `attendance`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | FK → users | |
| work_date | DATE | Business date |
| status | VARCHAR | WORKING / NOT_WORKING / HALF_DAY / LEAVE |
| is_working | BOOLEAN | Active flag |
| check_in_time | DATETIME | |
| check_out_time | DATETIME | |
| overtime_hours | DECIMAL | Admin adjustment |
| deduction_hours | DECIMAL | Admin adjustment |
| overtime_reason | TEXT | |
| deduction_reason | TEXT | |

#### `shops`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| code | VARCHAR UNIQUE | CAFE, BOOKSHOP, FOODHUT, COMMON |
| name | VARCHAR | Display name |

#### `shop_transactions`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| department | VARCHAR | Shop code |
| category | VARCHAR | SALE / EXPENSE |
| amount | DECIMAL | |
| item_name | VARCHAR | |
| comment | TEXT | |
| opening_balance | DECIMAL | Applies to SALE |
| closing_balance | DECIMAL | Applies to SALE |
| business_date | BIGINT | UTC midnight epoch ms |
| transaction_time | DATETIME | Actual time |
| expense_type_id | FK → expense_types | Optional |
| recorded_by | VARCHAR | User name |

#### `credits`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | FK → users | Customer |
| department | VARCHAR | Shop |
| amount | DECIMAL | |
| reason | TEXT | |
| is_paid | BOOLEAN | |
| created_at | DATETIME | |
| paid_at | DATETIME | Optional |

#### `expense_types`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| name | VARCHAR | |
| description | TEXT | Optional |
| created_at | DATETIME | |

#### `daily_cash`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| shop_id | FK → shops | |
| business_date | DATE | |
| opening_balance | DECIMAL | |
| closing_balance | DECIMAL | |
| recorded_at | DATETIME | |

#### `daily_summaries`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| shop_id | FK → shops | |
| business_date | DATE | UNIQUE per shop |
| total_sales | DECIMAL | |
| total_expenses | DECIMAL | |
| total_credits | DECIMAL | |
| profit | DECIMAL | |
| notes | TEXT | |

#### `cash_transactions`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| shop_id | FK → shops | |
| type | VARCHAR | IN / OUT |
| amount | DECIMAL | |
| description | TEXT | |
| transaction_date | DATE | |

#### `foodhut_items`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| name | VARCHAR | Item name |

#### `foodhut_item_variations`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| item_id | FK → foodhut_items | |
| variation | VARCHAR | Full / Half / etc. |
| price | DECIMAL | Selling price |
| cost | DECIMAL | Cost price |

#### `foodhut_sales`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| item_id | FK → foodhut_items | |
| variation_id | FK → variations | |
| item_name | VARCHAR | Snapshot |
| variation | VARCHAR | Snapshot |
| price | DECIMAL | |
| cost | DECIMAL | |
| quantity | INT | |
| action_type | VARCHAR | PREPARED / REMAINING |
| business_date | DATE | |
| transaction_time | DATETIME | |
| recorded_by | FK → users | |

#### `idea_of_the_week`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | FK → users | |
| title | VARCHAR | |
| description | TEXT | |
| week_date | DATE | |
| created_at | DATETIME | |

#### `improvement`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | FK → users | |
| title | VARCHAR | |
| description | TEXT | |
| status | VARCHAR | |
| created_at | DATETIME | |

#### `audit_logs`
| Column | Type | Notes |
|---|---|---|
| id | BIGINT PK | |
| user_id | FK → users | |
| action | VARCHAR | LOGIN / CREATE / UPDATE / DELETE |
| entity_type | VARCHAR | Table name |
| entity_id | BIGINT | Affected record |
| description | TEXT | Human-readable change |
| timestamp | DATETIME | |

---

## 8. API Reference

### Authentication

```
POST   /api/auth/register         Register a new user
POST   /api/auth/login             Login and get JWT token
GET    /api/auth/all-users         [SUPERADMIN] Get all users
```

### Users

```
GET    /api/users                  List all users
GET    /api/users/{id}             Get user by ID
POST   /api/users                  Create user
PUT    /api/users/{id}             Update user
DELETE /api/users/{id}             Delete user
```

### Attendance

```
GET    /api/attendance/today             Get today's attendance
PUT    /api/attendance/today             Update today status
POST   /api/attendance/check-in          Check in with timestamp
POST   /api/attendance/check-out         Check out with timestamp
POST   /api/attendance/working           Mark as working (YES)
POST   /api/attendance/not-working       Mark not working (NO)
GET    /api/attendance/history           My attendance history
GET    /api/attendance/all               [ADMIN] All staff attendance
PUT    /api/attendance/{id}/adjustments  [ADMIN] Set overtime/deduction
PUT    /api/attendance/update-status     [SUPERADMIN] Update by userId+date
PUT    /api/attendance/update-adjustments[SUPERADMIN] Adjust by userId+date
```

### Transactions (Shop Operations)

```
POST   /api/transactions                  Create transaction
GET    /api/transactions/daily            Today's transactions
GET    /api/transactions/by-date          Transactions by date
GET    /api/transactions/department-summary  Shop P&L summary
GET    /api/transactions/daily-summary    Shop daily summary
GET    /api/transactions/department-cash-total  Latest cash total
PUT    /api/transactions/{id}             [SUPERADMIN] Update
DELETE /api/transactions/{id}             [SUPERADMIN] Delete
```

### Credits

```
GET    /api/credits                   All credits
POST   /api/credits                   Add credit
GET    /api/credits/unpaid-total      Total unpaid credits
PUT    /api/credits/{id}/pay          Mark credit as paid
DELETE /api/credits/{id}              Delete credit
```

### Expense Types

```
GET    /api/expense-types             List all
POST   /api/expense-types             Create type
PUT    /api/expense-types/{id}        Update
DELETE /api/expense-types/{id}        Delete
```

### Food Hut Items

```
GET    /api/items                     Get all menu items + variations
POST   /api/items                     Add new item + variations
```

### Food Hut Sales

```
POST   /api/sales                     Record sale action (PREPARED/REMAINING)
GET    /api/sales/day                 Sales for a date
GET    /api/sales/summary             Today's summary (qty counts)
GET    /api/sales/remaining/{date}    Remaining for a specific date
DELETE /api/sales/{id}                Delete a sale entry
```

### Salary & Reports

```
GET    /api/salary/my                 My salary details
GET    /api/salary/all                [ADMIN] All staff salary
GET    /api/reports/attendance        Attendance report
GET    /api/reports/salary            Salary report
```

### Ideas & Improvements

```
GET    /api/ideas                     All ideas
POST   /api/ideas                     Submit idea
GET    /api/improvements              All improvements
POST   /api/improvements              Submit improvement
```

### Audit Logs

```
GET    /api/audit-logs               [SUPERADMIN] All audit logs
```

### Daily Cash

```
GET    /api/daily-cash               Get daily cash records
POST   /api/daily-cash               Save daily cash
GET    /api/admin/daily-cash         [ADMIN] Admin cash overview
```

---

## 9. User Roles & Permissions

| Permission | STAFF | ADMIN | SUPERADMIN | CUSTOMER |
|---|:---:|:---:|:---:|:---:|
| Login / Register | ✅ | ✅ | ✅ | ✅ |
| Mark own attendance | ✅ | ✅ | ✅ | ❌ |
| View own salary | ✅ | ✅ | ✅ | ❌ |
| Submit idea of week | ✅ | ✅ | ✅ | ❌ |
| Submit improvement | ✅ | ✅ | ✅ | ❌ |
| View shops (read) | ✅ | ✅ | ✅ | ✅ |
| Add transactions | ❌ | ✅ | ✅ | ❌ |
| Manage credits | ❌ | ✅ | ✅ | ❌ |
| Manage expense types | ❌ | ✅ | ✅ | ❌ |
| Edit/delete transactions | ❌ | ❌ | ✅ | ❌ |
| View all staff | ❌ | ❌ | ✅ | ❌ |
| Attendance reports | ❌ | ✅ | ✅ | ❌ |
| Salary reports | ❌ | ✅ | ✅ | ❌ |
| Business overview | ❌ | ❌ | ✅ | ❌ |
| Bank deposits | ❌ | ❌ | ✅ | ❌ |
| Audit logs | ❌ | ❌ | ✅ | ❌ |
| Ideas/improvements summary | ❌ | ❌ | ✅ | ❌ |
| User management | ❌ | ❌ | ✅ | ❌ |

---

## 10. Deployment & Infrastructure

### Server Setup

| Item | Value |
|---|---|
| OS | Linux (VPS) |
| Java | 17 |
| Application Port | 8080 |
| App Location | `/opt/oss/oss-1.0.0.jar` |
| DB Location | `/var/lib/oss/oss.db` |
| Service | systemd `oss.service` |

### Database Configuration

```properties
spring.datasource.url=jdbc:sqlite:/var/lib/oss/oss.db
# WAL mode enabled for 2-3x faster writes
# 25+ indexes for optimized queries
# Supports 100-500 concurrent users
```

### Systemd Service Management

```bash
sudo systemctl status oss.service
sudo systemctl start oss.service
sudo systemctl stop oss.service
sudo systemctl restart oss.service
sudo journalctl -u oss.service -f
```

### Build & Deploy

```bash
# Build
cd backend/
mvn clean package -DskipTests

# Upload to VPS
scp target/oss-1.0.0.jar root@your-vps:/opt/oss/

# Restart
ssh root@your-vps "sudo systemctl restart oss.service"
```

### Backup Strategy

- **Daily at 2 AM**: SQLite backup → gzipped file
- **Weekly**: JAR backup
- **Retention**: 7 days of DB backups, 4 JAR versions
- **Off-server sync**: rsync to secondary server or cloud storage

### Performance

| Metric | Value |
|---|---|
| DB Indexes | 25+ |
| Query speedup | 5–50x (vs no index) |
| WAL mode improvement | 2–3x faster writes |
| Expected concurrent users | 100–500 |
| RAM usage | 200–500 MB |

---

## 11. Roadmap: OneSolutions Unified App

### Concept

A single Flutter Android app **`onestopsolutions`** that merges OSS, OSD, and FoodHut into one unified application. Staff only need to install and use **one app**.

### Key Features

| Module | Features |
|---|---|
| **Auth** | Single sign-on, PIN lock, role-based access |
| **Home Hub** | Role-based dashboard with all module tiles |
| **Staff / HR** | Attendance, salary, ideas, improvements |
| **Shop Ops** | Daily transactions for Cafe/Bookshop/FoodHut |
| **Food Hut** | Prepared/sold/remaining tracking, menu mgmt |
| **Credits** | Customer credit management |
| **Reports** | Cross-module analytics |
| **Admin** | User management, audit logs, system settings |

### Navigation Structure

```
App Start
└── Splash / Auth Check
    ├── Login / Register
    └── PIN Entry
        └── Home Dashboard
            ├── 👥 Staff Module (OSS)
            │   ├── Attendance
            │   ├── Salary
            │   ├── Idea of Week
            │   └── Improvements
            ├── 🏪 Shop Operations (OSD)
            │   ├── Cafe
            │   ├── Bookshop
            │   ├── Food Hut (transactions)
            │   ├── Credits
            │   └── Bank Deposits
            ├── 🍽️ Food Hut (FoodHut)
            │   ├── Today's Dashboard
            │   ├── Add Items
            │   └── Sales History
            └── ⚙️ Admin (SUPERADMIN)
                ├── Business Overview
                ├── All Users
                ├── Reports
                └── Audit Logs
```

### Technical Plan

- **Single `pubspec.yaml`** combining all dependencies
- **Feature-based folder structure**: `lib/features/auth/`, `lib/features/staff/`, `lib/features/shop/`, `lib/features/foodhut/`
- **Shared services layer**: Single `ApiService` with all endpoints
- **Shared auth context**: Single JWT token storage via `flutter_secure_storage`
- **Single theme**: Unified brand colors

---

## 12. Roadmap: OSS Dashboard (Web)

### Concept

A **web-based owner dashboard** (`oss-dashboard`) accessible from browser (laptop/mobile). Provides:

- Real-time business intelligence across all 3 shops
- Staff management and analytics
- Financial reports, P&L summaries
- Credit tracking
- Attendance overview

### Tech Stack

| Layer | Technology |
|---|---|
| Framework | React 18 + Vite |
| UI Library | Tailwind CSS + shadcn/ui |
| Charts | Recharts |
| HTTP Client | Axios |
| State | React Context / Zustand |
| Auth | JWT (same backend) |

### Pages

| Page | Content |
|---|---|
| **Login** | Owner/admin authentication |
| **Dashboard** | Today's summary across all shops |
| **Shops** | Per-shop P&L, daily transactions |
| **Staff** | Staff list, attendance, salaries |
| **Credits** | Customer credits, payment tracking |
| **Food Hut** | Food item sales analytics |
| **Reports** | Date-range reports, export CSV |
| **Settings** | User management, expense types |
| **Audit Logs** | Full system activity log |

### Dashboard KPIs

- **Today's Revenue** (all shops combined)
- **Today's Expenses** (all shops combined)
- **Net Profit** (today / week / month)
- **Unpaid Credits Total**
- **Staff Present Today**
- **Food Hut: Prepared / Sold / Remaining**
- **Cash Balances per Shop**

---

## 📞 Quick Reference

### API Base URL
```
http://your-server-ip:8080
```

### Test Endpoint
```
GET /hello → "Hello OneStopSolutions!"
```

### Default Shops
```
CAFE     → Cafe Shop
BOOKSHOP → Book Shop
FOODHUT  → Food Hut
COMMON   → Common
```

### Salary Calculation
```
Net Salary = (Working Days × Daily Wage) + Overtime Pay − Deductions
```

---

*End of Documentation*

