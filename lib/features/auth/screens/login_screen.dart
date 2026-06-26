import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/auth/account_status.dart';
import 'package:festivo/core/navigation/post_auth_navigation.dart';

import '../state/login_ui_controller.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';

// ─────────────────────────────────────────────
// Constants local to auth screens
// ─────────────────────────────────────────────
const Color _kPrimaryPink   = Color(0xFFE58B97);
const Color _kLightPinkFill = Color(0xFFF9E7E9);
const Color _kGold          = Color(0xFFD4AF37);

// ─────────────────────────────────────────────
// Login Screen
// ─────────────────────────────────────────────
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Sign-in logic ─────────────────────────────────────────
  Future<void> _signIn() async {
    final ui = ref.read(loginUiControllerProvider);
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    ref.read(loginUiControllerProvider.notifier).setLoading(true);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        _showError('Account not found. Please create an account.');
        await _auth.signOut();
        return;
      }

      final data       = doc.data()!;
      final storedRole = data['role'] as String? ?? 'customer';

      if (AccountStatus.isSuspendedFromData(data)) {
        await _auth.signOut();
        if (!mounted) return;
        navigateToAccountSuspended(context);
        return;
      }

      const roleMap = {
        'customer'    : 'Customer',
        'venue_owner' : 'Venue Owner',
        'admin'       : 'Administrator',
      };
      final mappedRole = roleMap[storedRole.toLowerCase()] ?? 'Customer';

      if (mappedRole != ui.selectedRole) {
        _showError(
          "Role mismatch. You selected '${ui.selectedRole}' but your account is "
          "registered as '$mappedRole'.",
        );
        await _auth.signOut();
        return;
      }

      if (!mounted) return;

      navigateForRole(context, storedRole, userId: uid);
    } on FirebaseAuthException catch (e) {
      _showError(_authErrorMessage(e));
    } catch (_) {
      _showError('An unexpected error occurred.');
    } finally {
      ref.read(loginUiControllerProvider.notifier).setLoading(false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Sign in failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(loginUiControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildSecureBanner(),
            const SizedBox(height: 30),
            _buildRoleLabel(),
            const SizedBox(height: 12),
            _buildRoleSelector(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTextField(
                label: 'Email Address',
                hint: 'your@email.com',
                icon: Icons.email_outlined,
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTextField(
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline,
                controller: _passwordCtrl,
                isPassword: true,
                isObscured: ui.obscurePassword,
                onToggleVisibility: () =>
                    ref.read(loginUiControllerProvider.notifier).toggleObscure(),
              ),
            ),
            const SizedBox(height: 30),
            _buildSignInButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(color: _kGold, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Don't have an account?",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildCreateAccountButton(),
            const SizedBox(height: 30),
            const Text(
              '© 2026 Festivo. Premium Event Venue Platform',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1D4D8), Color(0xFFE58B97)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Image.asset(
                'assets/logo.jpeg',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(
                      width: 90,
                      height: 90,
                      child: Center(child: Text('🎉', style: TextStyle(fontSize: 50))),
                    ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to continue to Festivo',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFFE080)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, color: Color(0xFFFFC107), size: 22),
            SizedBox(width: 8),
            Text(
              'Secure Authentication',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C4A00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleLabel() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Select Your Role',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final ui = ref.watch(loginUiControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _roleCard(
            icon: Icons.person_outline,
            label: 'Customer',
            isSelected: ui.selectedRole == 'Customer',
            onTap: () =>
                ref.read(loginUiControllerProvider.notifier).selectRole('Customer'),
          ),
          const SizedBox(width: 12),
          _roleCard(
            icon: Icons.computer,
            label: 'Venue Owner',
            isSelected: ui.selectedRole == 'Venue Owner',
            onTap: () => ref
                .read(loginUiControllerProvider.notifier)
                .selectRole('Venue Owner'),
          ),
          const SizedBox(width: 12),
          _roleCard(
            icon: Icons.star_border,
            label: 'Administrator',
            isSelected: ui.selectedRole == 'Administrator',
            onTap: () => ref
                .read(loginUiControllerProvider.notifier)
                .selectRole('Administrator'),
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimaryPink : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _kPrimaryPink : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? isObscured : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimaryPink, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    final ui = ref.watch(loginUiControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: ui.isLoading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryPink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
          ),
          child: ui.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kPrimaryPink, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kPrimaryPink,
            ),
          ),
        ),
      ),
    );
  }
}
