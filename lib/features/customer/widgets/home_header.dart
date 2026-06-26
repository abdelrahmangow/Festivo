import 'package:flutter/material.dart';

import 'package:festivo/core/constants/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final bool isDark;
  final TextEditingController searchCtrl;
  final String displayName;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilterTap;

  const HomeHeader({
    super.key,
    required this.isDark,
    required this.searchCtrl,
    required this.displayName,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final d = isDark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent(d), AppColors.accent2(d)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.jpeg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Text('🎉', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Festivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Premium Event Venues',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: 21)),
                    Text(
                      'Welcome, $displayName!',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Discover premium venues for your perfect event',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(.6),
                  ),
                ),
                const SizedBox(height: 13),
                SearchBar(
                  ctrl: searchCtrl,
                  onChanged: onSearch,
                  onFilterTap: onFilterTap,
                  isDark: d,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool isDark;

  const SearchBar({
    super.key,
    required this.ctrl,
    required this.onChanged,
    required this.onFilterTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return Container(
      decoration: BoxDecoration(
        color: d ? AppColors.dGlight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12),
        ],
        border: d ? Border.all(color: AppColors.dGborder) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(Icons.search, size: 17, color: AppColors.textL(d)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: AppColors.textD(d)),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search venues...',
                hintStyle:
                    TextStyle(color: AppColors.textL(d), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: const Icon(
              Icons.filter_alt_outlined,
              size: 20,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

