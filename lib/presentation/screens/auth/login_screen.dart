import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickFill(String email, String role) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-filled $role credentials (password: "password")'),
        backgroundColor: AppTheme.primaryDarkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 36.0 : 24.0),
              decoration: BoxDecoration(
                color: AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha:0.12),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo & Title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha:0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.4), width: 2),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_rounded,
                          size: 42,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'JIMS',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Jeilo Inventory Management System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDarkSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Quick Demo Credentials Chips
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Demo Accounts:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickChip('Admin', 'admin@jeilo.com'),
                        _buildQuickChip('Manager', 'manager@jeilo.com'),
                        _buildQuickChip('Cashier', 'cashier@jeilo.com'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: AppTheme.textDarkSecondary),
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                        hintText: 'admin@jeilo.com',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter your email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: AppTheme.textDarkSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textDarkSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter your password';
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: AppTheme.primaryGreen.withValues(alpha:0.4),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sign In to JIMS',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Default password for all demo accounts: password',
                      style: TextStyle(fontSize: 11, color: AppTheme.textDarkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String email) {
    final isSelected = _emailController.text == email;
    return InkWell(
      onTap: () => _quickFill(email, label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha:0.25) : AppTheme.bgDarkCardHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderDark,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.person_outline,
              size: 14,
              color: isSelected ? AppTheme.primaryMint : AppTheme.textDarkSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
