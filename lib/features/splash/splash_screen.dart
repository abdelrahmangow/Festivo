import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:festivo/core/auth/account_status.dart';
import 'package:festivo/core/navigation/post_auth_navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Enhanced Splash Screen v2
//  • Animated logo (fade + scale)
//  • Animated loading dots (pulsing)
//  • Auth persistence: routes to correct screen on launch
//  • 5s max wait; Firestore timeout; always leaves splash
// ─────────────────────────────────────────────
class SplashScreenV2 extends StatefulWidget {
  const SplashScreenV2({super.key});

  @override
  State<SplashScreenV2> createState() => _SplashScreenV2State();
}

class _SplashScreenV2State extends State<SplashScreenV2>
    with TickerProviderStateMixin {
  static const _maxSplashDuration = Duration(seconds: 5);
  static const _firestoreTimeout = Duration(seconds: 3);
  static const _brandingDelay = Duration(milliseconds: 1200);

  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final AnimationController _dotCtrl;

  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoFade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoScale = Tween(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _logoCtrl.forward();
    _resolveAuth();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  // ── Auth resolution (never blocks splash forever) ───────────
  Future<void> _resolveAuth() async {
    debugPrint('[Splash] _resolveAuth started');

    try {
      await _resolveAuthBody().timeout(
        _maxSplashDuration,
        onTimeout: () {
          debugPrint(
            '[Splash] failsafe: max ${_maxSplashDuration.inSeconds}s elapsed',
          );
          throw TimeoutException('Splash auth resolution timed out');
        },
      );
    } catch (e, st) {
      debugPrint('[Splash] error: $e');
      debugPrint('[Splash] stack: $st');
      _goToLogin(reason: 'error: $e');
    }
  }

  Future<void> _resolveAuthBody() async {
    await Future.delayed(_brandingDelay);
    if (!mounted) return;

    debugPrint('[Splash] checking FirebaseAuth.currentUser');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[Splash] no signed-in user -> LoginScreen');
      _goToLogin(reason: 'no auth user');
      return;
    }

    debugPrint('[Splash] uid=${user.uid}, loading Firestore users/${user.uid}');
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .timeout(
          _firestoreTimeout,
          onTimeout: () {
            debugPrint(
              '[Splash] Firestore get timed out after ${_firestoreTimeout.inSeconds}s',
            );
            throw TimeoutException('Firestore user lookup timed out');
          },
        );

    if (!mounted) return;

    if (!doc.exists) {
      debugPrint('[Splash] user document missing -> LoginScreen');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('[Splash] signOut after missing doc failed: $e');
      }
      _goToLogin(reason: 'missing user document');
      return;
    }

    final data = doc.data();
    if (AccountStatus.isSuspendedFromData(data)) {
      debugPrint('[Splash] account suspended -> AccountSuspendedScreen');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('[Splash] signOut after suspension failed: $e');
      }
      _goToAccountSuspended();
      return;
    }

    final roleRaw = data?['role'] as String?;
    final role = (roleRaw == null || roleRaw.trim().isEmpty)
        ? 'customer'
        : roleRaw.trim().toLowerCase();

    debugPrint('[Splash] role=$role -> navigateForRole');
    _goToRole(role, user.uid);
  }

  void _goToLogin({required String reason}) {
    if (_navigationDone || !mounted) return;
    _navigationDone = true;
    debugPrint('[Splash] navigating to LoginScreen ($reason)');
    navigateToLogin(context);
  }

  void _goToAccountSuspended() {
    if (_navigationDone || !mounted) return;
    _navigationDone = true;
    debugPrint('[Splash] navigating to AccountSuspendedScreen');
    navigateToAccountSuspended(context);
  }

  void _goToRole(String role, String userId) {
    if (_navigationDone || !mounted) return;
    _navigationDone = true;
    debugPrint('[Splash] navigating for role=$role');
    navigateForRole(context, role, userId: userId);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8A0A7), Color(0xFFD98A92)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        '../../../assets/Festivo_Logo.png',
                        width: 68,
                        height: 68,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Text('🎉', style: TextStyle(fontSize: 52)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _logoFade,
                child: const Column(
                  children: [
                    Text(
                      'Festivo',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Premium Event Venues',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              AnimatedBuilder(
                animation: _dotCtrl,
                builder: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final offset = i / 3;
                    final v = ((_dotCtrl.value - offset) % 1.0).abs();
                    final opacity = (0.3 + v * 0.7).clamp(0.3, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
