import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedVisualIndex = 0;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      label: 'My Leaves',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Manage',
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings,
      branchIndex: 1,
    ),
  ];

  void _onTabTap(int visualIndex) {
    final tab = _tabs[visualIndex];
    if (tab.branchIndex == null) return;
    setState(() => _selectedVisualIndex = visualIndex);
    widget.navigationShell.goBranch(
      tab.branchIndex!,
      initialLocation: tab.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationBar(
      selectedIndex: _selectedVisualIndex,
      onDestinationSelected: _onTabTap,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.primaryContainer,
      destinations: _tabs.map((tab) {
        final isStub = tab.branchIndex == null;
        return NavigationDestination(
          icon: Opacity(opacity: isStub ? 0.4 : 1.0, child: Icon(tab.icon)),
          selectedIcon: Opacity(
            opacity: isStub ? 0.4 : 1.0,
            child: Icon(tab.selectedIcon),
          ),
          label: tab.label,
        );
      }).toList(),
    );
  }
}
