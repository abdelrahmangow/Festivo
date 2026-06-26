import 'package:flutter/material.dart';

import 'package:festivo/core/constants/app_colors.dart';

void showToast(BuildContext ctx, String msg, bool isDark) {
  final overlay = Overlay.of(ctx);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.of(ctx).padding.top + 16,
      left: 20,
      right: 20,
      child: ToastBanner(
        message: msg,
        isDark: isDark,
        onDone: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class ToastBanner extends StatefulWidget {
  final String message;
  final bool isDark;
  final VoidCallback onDone;
  const ToastBanner({
    super.key,
    required this.message,
    required this.isDark,
    required this.onDone,
  });

  @override
  State<ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<ToastBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _slide = Tween(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), _dismiss);
  }

  void _dismiss() async {
    if (mounted) {
      await _ctrl.reverse();
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: d ? AppColors.dNavy : AppColors.softRose,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [AppColors.shadowMd(d)],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

