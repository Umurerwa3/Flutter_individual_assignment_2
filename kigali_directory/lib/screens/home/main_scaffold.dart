import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../directory/directory_screen.dart';
import '../my_listings/my_listings_screen.dart';
import '../map_view/map_view_screen.dart';
import '../settings/settings_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final listing = context.read<ListingProvider>();
    listing.listenAll();
    if (auth.user != null) listing.listenMine(auth.user!.uid);
    listing.fetchLocation();
  }

  @override
  Widget build(BuildContext ctx) {
    final screens = [
      const DirectoryScreen(),
      const MyListingsScreen(),
      const MapViewScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: screens[_idx],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A2D42),
        indicatorColor: const Color.fromARGB(51, 245, 166, 35),
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.explore, color: Color(0xFFF5A623)),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFFF5A623)),
            label: 'My Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.map, color: Color(0xFFF5A623)),
            label: 'Map View',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.white54),
            selectedIcon: Icon(Icons.settings, color: Color(0xFFF5A623)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}