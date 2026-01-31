// widgets/emergency_scaffold.dart
import 'package:flutter/material.dart';
import 'emergency_banner.dart';
import 'top_bar.dart';
import 'app_drawer.dart';
import 'bottom_navigation.dart';

class EmergencyScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final bool showEmergencyBanner;
  final bool showBottomNav;
  final int selectedNavIndex;
  final Function(int)? onNavItemTapped;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const EmergencyScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.showBackButton = false,
    this.showEmergencyBanner = false,
    this.showBottomNav = true,
    this.selectedNavIndex = 0,
    this.onNavItemTapped,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: title,
        showBackButton: showBackButton,
      ),
      endDrawer: const AppDrawer(),
      body: body,
      bottomNavigationBar: showBottomNav
          ? BottomNavigationWidget(
              selectedIndex: selectedNavIndex,
              onItemTapped: onNavItemTapped ?? (_) {},
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}