import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'router/app_router.dart';

// AppSheet brand colors
const kAppBlue = Color(0xFF1A73E8);
const kAppBlueSurface = Color(0xFFE8F0FE);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Atma Grosir POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAppBlue,
          primary: kAppBlue,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAppBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: kAppBlueSurface,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: kAppBlue, size: 22);
            }
            return IconThemeData(color: Colors.grey.shade500, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: kAppBlue, fontSize: 11, fontWeight: FontWeight.w600);
            }
            return TextStyle(color: Colors.grey.shade500, fontSize: 11);
          }),
          elevation: 8,
          shadowColor: Colors.black26,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 8,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
          space: 0,
        ),
        chipTheme: ChipThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kAppBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: kAppBlue, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIconColor: Colors.grey.shade500,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, Key? key})
      : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _onTap(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(LucideIcons.layoutDashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.shoppingCart),
                  label: 'POS',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.package),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.users),
                  label: 'Partners',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.receipt),
                  label: 'Sales',
                ),
              ],
            ),
          );
        }

        // Desktop / Tablet layout
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (int index) => _onTap(context, index),
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                selectedIconTheme: const IconThemeData(color: kAppBlue),
                selectedLabelTextStyle: const TextStyle(
                    color: kAppBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                unselectedLabelTextStyle:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
                indicatorColor: kAppBlueSurface,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.layoutDashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.shoppingCart),
                    label: Text('POS'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.package),
                    label: Text('Inventory'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.users),
                    label: Text('Partners'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(LucideIcons.receipt),
                    label: Text('Sales'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
