import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import 'agent_profile_screen.dart';

class AgentManagementScreen extends ConsumerWidget {
  const AgentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agent Management',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: agentsAsync.when(
        data: (agents) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.adminPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: AppTheme.adminPrimaryColor, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'New agents must sign up at the login screen first. You can then activate them here.',
                          style: TextStyle(
                            color: AppTheme.adminTextColor.withOpacity(0.8), 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (agents.isEmpty)
                const Expanded(
                  child: Center(child: Text('No agents found')),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: agents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AgentProfileScreen(agent: agent),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: ListTile(
                            leading: Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: agent.isActive 
                                    ? AppTheme.adminAccentRevenue.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                color: agent.isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              agent.fullName ?? agent.email ?? 'Agent ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  agent.email ?? 'No email',
                                  style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: agent.isActive 
                                            ? AppTheme.adminAccentRevenue.withOpacity(0.1) 
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        agent.isActive ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: agent.isActive ? AppTheme.adminAccentRevenue : Colors.grey.shade600,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.touch_app_rounded, size: 12, color: AppTheme.adminPrimaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            'View Profile',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.adminPrimaryColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Switch(
                              value: agent.isActive,
                              activeColor: AppTheme.adminAccentRevenue,
                              activeTrackColor: AppTheme.adminAccentRevenue.withOpacity(0.2),
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.grey.shade200,
                              onChanged: (value) async {
                                try {
                                  final agentRepo = ref.read(agentRepositoryProvider);
                                  await agentRepo.toggleAgentActive(agent.id, value);
                                  ref.invalidate(agentsListProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value ? 'Agent activated' : 'Agent deactivated',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: AppTheme.adminPrimaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: AppTheme.adminAccentAlert,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(agentsListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
