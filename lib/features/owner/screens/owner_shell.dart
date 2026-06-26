import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/features/owner/screens/owner_add_venue_screen.dart';
import 'package:festivo/features/owner/screens/owner_bookings_screen.dart';
import 'package:festivo/features/owner/screens/owner_dashboard_screen.dart';
import 'package:festivo/features/owner/screens/owner_profile_screen.dart';
import 'package:festivo/features/owner/theme/owner_colors.dart';
import 'package:flutter_riverpod/legacy.dart';

final ownerTabIndexProvider = StateProvider<int>((ref) => 0);

class OwnerShell extends ConsumerWidget {
  const OwnerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(ownerTabIndexProvider);

    final pages = [
      OwnerDashboardScreen(
        onAddTap: () => ref.read(ownerTabIndexProvider.notifier).state = 2,
      ),
      const OwnerBookingsScreen(),
      OwnerAddVenueScreen(
        onDone: () => ref.read(ownerTabIndexProvider.notifier).state = 0,
      ),
      const OwnerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: OwnerColors.white,
          border: Border(top: BorderSide(color: OwnerColors.pinkBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Dashboard',
                active: index == 0,
                onTap: () => ref.read(ownerTabIndexProvider.notifier).state = 0,
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Bookings',
                active: index == 1,
                onTap: () => ref.read(ownerTabIndexProvider.notifier).state = 1,
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Add',
                active: index == 2,
                onTap: () => ref.read(ownerTabIndexProvider.notifier).state = 2,
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: index == 3,
                onTap: () => ref.read(ownerTabIndexProvider.notifier).state = 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46,
                height: 28,
                decoration: BoxDecoration(
                  color: active ? OwnerColors.pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: active ? OwnerColors.white : OwnerColors.textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? OwnerColors.pink : OwnerColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
