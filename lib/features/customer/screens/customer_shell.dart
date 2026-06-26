import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/app/providers/app_providers.dart';
import 'package:festivo/core/constants/app_colors.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'customer_bookings_screen.dart';
import 'customer_favorites_screen.dart';
import 'customer_home.dart';
import 'customer_profile_screen.dart';

final customerTabIndexProvider = StateProvider<int>((_) => 0);

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(isDarkProvider);
    final index = ref.watch(customerTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomeScreen(),
          CustomerFavoritesScreen(),
          CustomerBookingsScreen(),
          CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        isDark: dark,
        currentIndex: index,
        onTap: (i) => ref.read(customerTabIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final bool isDark;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.isDark,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItem(Icons.home_outlined, Icons.home, 'Home'),
      _NavItem(Icons.favorite_border, Icons.favorite, 'Favorites'),
      _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Bookings'),
      _NavItem(Icons.person_outline, Icons.person, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBar(isDark),
        border: Border(top: BorderSide(color: AppColors.border(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.accent(isDark)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active
                              ? Colors.white
                              : AppColors.textL(isDark),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppColors.accent(isDark)
                              : AppColors.textL(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}
