import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/theme/app_theme.dart';
import 'package:onestopsolutions/features/auth/services/pin_service.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/screens/login_screen.dart';
import 'package:onestopsolutions/home/home_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup;
  const PinScreen({super.key, required this.isSetup});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final List<String> _pin = [];
  String? _error;
  String? _firstPin; // For setup confirmation

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(digit);
      _error = null;
    });
    if (_pin.length == 4) _handlePinComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _handlePinComplete() async {
    final entered = _pin.join();

    if (widget.isSetup) {
      if (_firstPin == null) {
        // First entry — save and ask to confirm
        setState(() {
          _firstPin = entered;
          _pin.clear();
        });
      } else {
        // Second entry — confirm
        if (entered == _firstPin) {
          await PinService.setPin(entered);
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          setState(() {
            _pin.clear();
            _firstPin = null;
            _error = 'PINs do not match. Try again.';
          });
        }
      }
    } else {
      // Verify mode
      final valid = await PinService.verifyPin(entered);
      if (!mounted) return;
      if (valid) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() {
          _pin.clear();
          _error = 'Incorrect PIN. Try again.';
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    await PinService.clearPin();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_firstPin == null ? 'Create PIN' : 'Confirm PIN')
        : 'Enter PIN';
    final subtitle = widget.isSetup
        ? (_firstPin == null ? 'Choose a 4-digit PIN to secure the app' : 'Re-enter your PIN to confirm')
        : 'Enter your 4-digit PIN to continue';

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? Colors.white : Colors.white.withOpacity(0.3),
                ),
              )),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
              ),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80),
                      _buildKey('0'),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: InkWell(
                          onTap: _onDelete,
                          borderRadius: BorderRadius.circular(40),
                          child: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (!widget.isSetup)
              TextButton(
                onPressed: _logout,
                child: Text('Logout', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map(_buildKey).toList(),
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onKey(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
