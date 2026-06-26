import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/create_account_ui_controller.dart';

// ─────────────────────────────────────────────
// Create Account Screen
// ─────────────────────────────────────────────

const Color _kScreenPrimaryPink = Color(0xFFE88A98);
const Color _kLightPinkFill     = Color(0xFFF9E7E9);
const Color _kGold              = Color(0xFFD4AF37);

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  String _roleToFirestore(String uiRole) {
    switch (uiRole) {
      case 'Venue Owner':
        return 'venue_owner';
      default:
        return 'customer';
    }
  }

  Future<void> _createAccount() async {
    final ui = ref.read(createAccountUiControllerProvider);
    final name            = _nameCtrl.text.trim();
    final email           = _emailCtrl.text.trim();
    final phone           = _phoneCtrl.text.trim();
    final password        = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    ref.read(createAccountUiControllerProvider.notifier).setLoading(true);

    String? uid;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please choose a stronger one.';
          break;
        default:
          message = e.message ?? 'Account creation failed.';
      }
      if (mounted) {
        ref.read(createAccountUiControllerProvider.notifier).setLoading(false);
        _showError(message);
      }
      return;
    } catch (e) {
      if (mounted) {
        ref.read(createAccountUiControllerProvider.notifier).setLoading(false);
        _showError('Unexpected error: $e');
      }
      return;
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': _roleToFirestore(ui.selectedAccountType),
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (_) {/* non-fatal */}

    _auth.signOut().catchError((_) {});

    if (!mounted) return;
    ref.read(createAccountUiControllerProvider.notifier).setLoading(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! Please sign in.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
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
    final ui = ref.watch(createAccountUiControllerProvider);
    return Scaffold(
      backgroundColor: _kScreenPrimaryPink,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopSection(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 25,
                    ),
                    child: _buildForm(ui, ref),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              'assets/logo.jpeg',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Text('🎉', style: TextStyle(fontSize: 35))),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join Festivo to discover premium venues',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(CreateAccountUiState ui, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _styledTextField(
          label: 'Full Name',
          hint: 'Your full name',
          icon: Icons.person_outline,
          controller: _nameCtrl,
        ),
        const SizedBox(height: 16),
        _styledTextField(
          label: 'Email Address',
          hint: 'your@email.com',
          icon: Icons.email_outlined,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _styledTextField(
          label: 'Phone Number',
          hint: '+20 1XX XXX XXXX',
          icon: Icons.phone_outlined,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _styledTextField(
          label: 'Password',
          hint: 'Min 8 characters',
          icon: Icons.lock_outline,
          controller: _passwordCtrl,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _styledTextField(
          label: 'Confirm Password',
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          controller: _confirmPasswordCtrl,
          isPassword: true,
        ),
        const SizedBox(height: 20),
        const Text(
          'Account Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _accountTypeCard(
              label: 'Customer',
              icon: Icons.person,
              iconColor: Colors.blue,
              isSelected: ui.selectedAccountType == 'Customer',
              onTap: () => ref
                  .read(createAccountUiControllerProvider.notifier)
                  .selectAccountType('Customer'),
            ),
            const SizedBox(width: 12),
            _accountTypeCard(
              label: 'Venue Owner',
              icon: Icons.account_balance,
              iconColor: Colors.blueGrey,
              isSelected: ui.selectedAccountType == 'Venue Owner',
              onTap: () => ref
                  .read(createAccountUiControllerProvider.notifier)
                  .selectAccountType('Venue Owner'),
            ),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: ui.isLoading ? null : _createAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kScreenPrimaryPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
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
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: TextStyle(
                      color: _kGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _styledTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: _kLightPinkFill,
            prefixIcon: Icon(icon, color: Colors.grey.shade500),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _accountTypeCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? _kScreenPrimaryPink : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? _kScreenPrimaryPink
                  : const Color(0xFFF1D4D8),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : iconColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
