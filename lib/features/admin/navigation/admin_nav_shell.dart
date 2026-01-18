import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../agents/agent_management_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../products/product_catalog_screen.dart';
import '../settings/system_settings_screen.dart';
import '../customers/customer_list_screen.dart';

class AdminNavShell extends StatefulWidget {
  const AdminNavShell({super.key});

  @override
  State<AdminNavShell> createState() => _AdminNavShellState();
}

class _AdminNavShellState extends State<AdminNavShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const CustomerListScreen(),
    const AgentManagementScreen(),
    const ProductCatalogScreen(),
    const SystemSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppTheme.adminPrimaryColor,
          unselectedItemColor: AppTheme.adminTextColor.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), 
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Stats'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Customers'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge_rounded),
              label: 'Agents'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Products'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings'
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
