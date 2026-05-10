import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/theme/app_theme.dart';
import 'package:onestopsolutions/features/auth/services/auth_service.dart';
import 'package:onestopsolutions/features/auth/services/pin_service.dart';
import 'package:onestopsolutions/features/auth/screens/register_screen.dart';
import 'package:onestopsolutions/features/auth/screens/pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());

      if (!mounted) return;
      setState(() => _loading = false);

      if (result != null) {
        final hasPinSet = await PinService.hasPinSet();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PinScreen(isSetup: !hasPinSet)),
        );
      } else {
        setState(() => _error = 'Invalid email or password. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Please check your internet and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/logo-icon.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'OneStopSolutions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Sign in to continue',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 16),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text("Don't have an account? Register"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
