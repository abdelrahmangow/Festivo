import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:festivo/core/constants/app_colors.dart';
import 'package:festivo/features/customer/domain/customer_models.dart';
import 'package:flutter_riverpod/legacy.dart';

final _filterCatProvider = StateProvider.autoDispose<String>((ref) => 'All');
final _filterMinProvider = StateProvider.autoDispose<int>((ref) => 0);
final _filterMaxProvider = StateProvider.autoDispose<int>((ref) => 999999);

class FilterPanel extends ConsumerStatefulWidget {
  final bool isDark;
  final String selectedCat;
  final int priceMin, priceMax;
  final void Function(String cat, int min, int max) onApply;
  final VoidCallback onReset;

  const FilterPanel({
    super.key,
    required this.isDark,
    required this.selectedCat,
    required this.priceMin,
    required this.priceMax,
    required this.onApply,
    required this.onReset,
  });

  @override
  ConsumerState<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends ConsumerState<FilterPanel> {
  late TextEditingController _minCtrl, _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: widget.priceMin.toString());
    _maxCtrl = TextEditingController(
      text: widget.priceMax == 999999 ? '100000' : widget.priceMax.toString(),
    );
    ref.read(_filterCatProvider.notifier).state = widget.selectedCat;
    ref.read(_filterMinProvider.notifier).state = widget.priceMin;
    ref.read(_filterMaxProvider.notifier).state = widget.priceMax;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final cat = ref.watch(_filterCatProvider);
    final min = ref.watch(_filterMinProvider);
    final max = ref.watch(_filterMaxProvider);
    return Container(
      decoration: BoxDecoration(
        color: d ? AppColors.dGlight : AppColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(d),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Venues',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textD(d),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: d ? AppColors.dGlight : AppColors.glightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, size: 16, color: AppColors.textM(d)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textD(d),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kCategories.map((c) {
              final active = cat == c.label;
              return GestureDetector(
                onTap: () {
                  ref.read(_filterCatProvider.notifier).state = c.label;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.accent(d) : AppColors.card(d),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: active ? AppColors.accent(d) : AppColors.border(d),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${c.emoji} ${c.label}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textM(d),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Price Range (EGP)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textD(d),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _priceBox('Min', _minCtrl, d, (v) {
                  ref.read(_filterMinProvider.notifier).state = v;
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _priceBox('Max', _maxCtrl, d, (v) {
                  ref.read(_filterMaxProvider.notifier).state = v;
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(_filterCatProvider.notifier).state = 'All';
                    ref.read(_filterMinProvider.notifier).state = 0;
                    ref.read(_filterMaxProvider.notifier).state = 100000;
                    _minCtrl.text = '0';
                    _maxCtrl.text = '100000';
                    widget.onReset();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent(d),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent(d),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    widget.onApply(cat, min, max == 999999 ? 999999 : max);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent(d),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent(d).withOpacity(.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _priceBox(
    String hint,
    TextEditingController ctrl,
    bool d,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: d ? AppColors.dGlight : AppColors.glightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(d), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 15, color: AppColors.textD(d)),
        onChanged: (s) => onChanged(int.tryParse(s) ?? 0),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textL(d)),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}
