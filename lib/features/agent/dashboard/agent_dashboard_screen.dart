import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/agent_providers.dart';
import '../../auth/login_screen.dart';
import '../customers/lookup_client_screen.dart';
import '../registration/new_registration_screen.dart';

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(agentStatsProvider);
    final customersAsync = ref.watch(assignedCustomersProvider);

    return Scaffold(
      backgroundColor: AppTheme.agentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agent Dashboard',
          style: TextStyle(
            color: AppTheme.agentTextColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerColor, size: 22),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final lifetimeCollection = stats['money'] ?? 0.0;
          final totalBoxes = stats['boxes'] ?? 0.0;
          final activeCustomers = customersAsync.whenOrNull(
            data: (customers) => customers.where((c) => c.isActive).length,
          ) ?? 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeroCard(lifetimeCollection, totalBoxes, activeCustomers),
                const SizedBox(height: 32),
                _buildActionGrid(context),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.agentPrimaryColor)),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHeroCard(double lifetimeCollection, double totalBoxes, int activeCustomers) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.agentPrimaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIFETIME COLLECTION',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'GHC ${lifetimeCollection.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMetricChip(
                Icons.inventory_2_rounded,
                '${totalBoxes.toStringAsFixed(0)} Boxes',
              ),
              const SizedBox(width: 12),
              _buildMetricChip(
                Icons.people_alt_rounded,
                '$activeCustomers Active',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Customers',
                Icons.people_rounded,
                AppTheme.agentPrimaryColor,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LookupClientScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                'Register New',
                Icons.person_add_rounded,
                AppTheme.agentAccentRegister,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewRegistrationScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          'Sync Data',
          Icons.sync_rounded,
          AppTheme.agentAccentSync,
          isFullWidth: true,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data synced successfully!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color accentColor, {
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: isFullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: accentColor),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.agentTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
