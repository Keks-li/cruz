import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../providers/agent_providers.dart';
import '../../../providers/admin_providers.dart';
import '../dashboard/agent_dashboard_screen.dart';
import '../customers/lookup_client_screen.dart';
import '../ledger/collection_ledger_screen.dart';
import '../registration/new_registration_screen.dart';

class AgentNavShell extends ConsumerStatefulWidget {
  const AgentNavShell({super.key});

  @override
  ConsumerState<AgentNavShell> createState() => _AgentNavShellState();
}

class _AgentNavShellState extends ConsumerState<AgentNavShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AgentDashboardScreen(),
    const LookupClientScreen(),
    const CollectionLedgerScreen(),
    const NewRegistrationScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    
    setState(() => _selectedIndex = index);

    // Force refresh data when switching tabs to ensure freshness
    switch (index) {
      case 0: // Dashboard
        ref.invalidate(agentDailyCollectionProvider);
        ref.invalidate(agentRegistrationStatsProvider);
        ref.invalidate(agentStatsProvider);
        ref.invalidate(agentCustomerCountProvider);
        ref.invalidate(agentDailyPaymentsProvider);
        break;
      case 2: // Ledger
        ref.invalidate(agentPaymentsProvider);
        break;
      case 1: // Lookup
        ref.invalidate(assignedCustomersProvider);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: _onItemTapped,
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
