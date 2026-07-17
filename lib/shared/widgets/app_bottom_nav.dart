import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Election-green accent used by the floating bottom navigation.
const Color _navAccent = Color(0xFF0F8A5F);
const Color _navAccentDark = Color(0xFF0B6B49);

/// A single bottom-navigation entry.
class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCenter = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isCenter;
}

/// Floating glass-style bottom navigation bar with a raised central scan
/// action, mirroring the EVM design system shell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.activeIndex,
    super.key,
  });

  final List<BottomNavItem> items;

  /// Index of the active tab, or -1 when no tab is highlighted.
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.slate100),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _navAccent.withValues(alpha: 0.14),
              blurRadius: 40,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                _NavButton(item: items[i], active: i == activeIndex),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active});

  final BottomNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? _navAccent : AppColors.slate400;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (item.isCenter)
            Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[_navAccent, _navAccentDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _navAccent.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
            )
          else
            Container(
              width: 40,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? _navAccent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: color, size: 19),
            ),
          Transform.translate(
            offset: Offset(0, item.isCenter ? -14 : 2),
            child: Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: item.isCenter ? _navAccent : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
