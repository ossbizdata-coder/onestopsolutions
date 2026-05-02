import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/theme/app_theme.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/services/pin_service.dart';
import 'package:onestopsolutions/features/auth/screens/login_screen.dart';
import 'package:onestopsolutions/features/auth/screens/pin_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const OneStopSolutionsApp());
}

class OneStopSolutionsApp extends StatelessWidget {
  const OneStopSolutionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneStopSolutions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const SplashGate(),
    );
  }
}

/// Determines the initial route based on auth state and PIN status
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      _go(const LoginScreen());
      return;
    }

    final hasPinSet = await PinService.hasPinSet();
    if (!hasPinSet) {
      _go(const PinScreen(isSetup: true));
      return;
    }

    final isSessionValid = await PinService.isSessionValid();
    if (!isSessionValid) {
      await PinService.clearSession();
      _go(const LoginScreen());
      return;
    }

    _go(const PinScreen(isSetup: false));
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // App Logo
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'OneStopSolutions',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cafe · Bookshop · Food Hut',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }
}

