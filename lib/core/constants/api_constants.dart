/// Central place for all API endpoint constants
class ApiConstants {
  // ── PRODUCTION SERVERS ─────────────────────────────────────────────────
  // Current: Direct IP (no SSL)
  // Switch to domain once DNS + SSL is configured on the VPS:
  //   static const String baseUrl = 'https://www.onestopdaily.shop';
  static const String baseUrl = 'http://74.208.132.78';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String allUsers = '/api/auth/all-users';

  // Users
  static const String users = '/api/users';

  // Attendance
  static const String attendanceToday = '/api/attendance/today';
  static const String attendanceCheckIn = '/api/attendance/check-in';
  static const String attendanceCheckOut = '/api/attendance/check-out';
  static const String attendanceWorking = '/api/attendance/working';
  static const String attendanceNotWorking = '/api/attendance/not-working';
  static const String attendanceHistory = '/api/attendance/history';
  static const String attendanceAll = '/api/attendance/all';
  static String attendanceUpdateStatus(id) => '/api/attendance/$id/adjustments';

  // Transactions (Shop Operations)
  static const String transactions = '/api/transactions';
  static const String transactionsDaily = '/api/transactions/daily';
  static const String transactionsByDate = '/api/transactions/by-date';
  static const String transactionsDeptSummary = '/api/transactions/department-summary';
  static const String transactionsDailySummary = '/api/transactions/daily-summary';
  static const String transactionsCashTotal = '/api/transactions/department-cash-total';

  // Credits
  static const String credits = '/api/credits';
  static const String creditsUnpaidTotal = '/api/credits/unpaid-total';
  static String creditPay(id) => '/api/credits/$id/pay';

  // Expense Types
  static const String expenseTypes = '/api/expense-types';

  // Food Hut Items
  static const String items = '/api/items';

  // Food Hut Sales
  static const String sales = '/api/sales';
  static const String salesSummary = '/api/sales/day/summary';
  static String salesForDay(String date) => '/api/sales/day?date=$date';
  static String salesRemaining(String date) => '/api/sales/remaining/$date';

  // Salary
  static const String salarySelf = '/api/salary/my';
  static const String salaryAll = '/api/salary/all';

  // Reports
  static const String reportsAttendance = '/api/reports/attendance';
  static const String reportsSalary = '/api/reports/salary';

  // Feedback
  static const String feedback = '/api/ideas';

  // Daily Cash
  static const String dailyCash = '/api/daily-cash';
  static const String adminDailyCash = '/api/admin/daily-cash';

  // Audit Logs
  static const String auditLogs = '/api/audit-logs';
}

