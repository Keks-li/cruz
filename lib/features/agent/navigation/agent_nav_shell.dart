import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../dashboard/agent_dashboard_screen.dart';
import '../customers/lookup_client_screen.dart';
import '../ledger/collection_ledger_screen.dart';
import '../registration/new_registration_screen.dart';

class AgentNavShell extends StatefulWidget {
  const AgentNavShell({super.key});

  @override
  State<AgentNavShell> createState() => _AgentNavShellState();
}

class _AgentNavShellState extends State<AgentNavShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AgentDashboardScreen(),
    const LookupClientScreen(),
    const CollectionLedgerScreen(),
    const NewRegistrationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Explicit debug print
    debugPrint('Building AgentNavShell with $_selectedIndex');
    
    return Scaffold(
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
          selectedItemColor: AppTheme.agentPrimaryColor,
          unselectedItemColor: AppTheme.agentTextColor.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), 
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_search_outlined),
              activeIcon: Icon(Icons.person_search_rounded),
              label: 'Lookup'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Ledger'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_outlined),
              activeIcon: Icon(Icons.person_add_rounded),
              label: 'Register'
            ),
          ],
        ),
      ),
    );
  }
}
