import 'package:flutter/material.dart';

import '../../core/app_store_scope.dart';
import '../../core/theme.dart';

class RoleDestination {
  const RoleDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class RoleScaffold extends StatefulWidget {
  const RoleScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.pages,
    required this.onSignOut,
  }) : assert(destinations.length == pages.length);

  final String title;
  final List<RoleDestination> destinations;
  final List<Widget> pages;
  final VoidCallback onSignOut;

  @override
  State<RoleScaffold> createState() => _RoleScaffoldState();
}

class _RoleScaffoldState extends State<RoleScaffold> {
  int _index = 0;

  Widget _sidebarHeader(BuildContext context) {
    final store = AppStoreScope.of(context);
    final account = store.currentAccount;
    final roleTheme = Theme.of(context).extension<FoodHubRoleTheme>();
    final accent = roleTheme?.accent ?? Theme.of(context).colorScheme.primary;

    String initials(String name) {
      final parts = name
          .trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'FH';
      final a = parts.first.characters.first;
      final b = parts.length > 1 ? parts.last.characters.first : '';
      return (a + b).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withAlpha(20),
                  border: Border.all(color: accent.withAlpha(90)),
                ),
                child: Icon(Icons.restaurant_rounded, color: accent),
              ),
              const SizedBox(width: 10),
              Flexible(
                fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Hub',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (account != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: accent.withAlpha(18),
                      foregroundColor: accent,
                      child: Text(initials(account.displayName)),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            account.role.name.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(letterSpacing: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Divider(height: 1, color: Theme.of(context).dividerTheme.color),
        ],
      ),
    );
  }

  Widget _sidebarFooter(BuildContext context) {
    final store = AppStoreScope.of(context);
    final roleTheme = Theme.of(context).extension<FoodHubRoleTheme>();
    final accent = roleTheme?.accent ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: store.toggleThemeMode,
            icon: Icon(
              store.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            label: Text(
              store.themeMode == ThemeMode.dark ? 'Light mode' : 'Dark mode',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(width: 1.5, color: accent),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStoreScope.of(context);
    final roleTheme = Theme.of(context).extension<FoodHubRoleTheme>();
    final sidebarBg =
        roleTheme?.sidebarBackground ?? Theme.of(context).colorScheme.surface;
    final onSidebar =
        roleTheme?.onSidebar ?? Theme.of(context).colorScheme.onSurface;
    final accent = roleTheme?.accent ?? Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isVeryWide = constraints.maxWidth >= 1100;

        final currentDestination = widget.destinations[_index].label;

        final showAppBarActions = !isWide;

        final appBar = AppBar(
          title: Text(currentDestination),
          leading: isWide
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Center(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
          leadingWidth: isWide ? null : 110,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: accent),
          ),
          actions: !showAppBarActions
              ? null
              : [
                  IconButton(
                    tooltip: store.themeMode == ThemeMode.dark
                        ? 'Light mode'
                        : 'Dark mode',
                    onPressed: store.toggleThemeMode,
                    icon: Icon(
                      store.themeMode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout),
                  ),
                ],
        );

        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  extended: isVeryWide,
                  minExtendedWidth: 240,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  backgroundColor: sidebarBg,
                  indicatorColor: accent.withAlpha(24),
                  selectedIconTheme: IconThemeData(color: accent),
                  selectedLabelTextStyle: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: accent),
                  unselectedIconTheme: IconThemeData(
                    color: onSidebar.withAlpha(184),
                  ),
                  unselectedLabelTextStyle: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: onSidebar.withAlpha(184)),
                  leading: _sidebarHeader(context),
                  trailing: _sidebarFooter(context),
                  destinations: [
                    for (final d in widget.destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerTheme.color,
                ),
                Expanded(child: widget.pages[_index]),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: widget.pages[_index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (value) => setState(() => _index = value),
            items: [
              for (final d in widget.destinations)
                BottomNavigationBarItem(icon: Icon(d.icon), label: d.label),
            ],
          ),
        );
      },
    );
  }
}
