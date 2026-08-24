import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/responsive.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';
import '../../../data/models/zone.dart';
import '../../../data/models/cycle.dart';
import '../../auth/login_screen.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  final _regFeeController = TextEditingController();
  final _zoneController = TextEditingController();
  final _cycleNameController = TextEditingController();

  @override
  void dispose() {
    _regFeeController.dispose();
    _zoneController.dispose();
    _cycleNameController.dispose();
    super.dispose();
  }

  void _showCreateCycleDialog() {
    _cycleNameController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Business Cycle', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: _cycleNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Cycle Name',
            hintText: 'e.g. Cycle 3',
            filled: true,
            fillColor: AppTheme.adminInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final name = _cycleNameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref.read(cycleRepositoryProvider).createCycle(name);
                ref.invalidate(cyclesListProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cycle "$name" created'),
                      backgroundColor: AppTheme.adminAccentRevenue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.adminAccentAlert,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCloseCycleDialog(Cycle cycle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Cycle', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Close "${cycle.name}"?\n\nAgents will no longer be able to record new payments until another cycle is activated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminAccentAlert,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                await ref.read(cycleRepositoryProvider).closeCycle(cycle.id);
                ref.invalidate(cyclesListProvider);
                ref.invalidate(activeCycleProvider);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${cycle.name}" has been closed'),
                      backgroundColor: Colors.orange.shade700,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.adminAccentAlert,
                    ),
                  );
                }
              }
            },
            child: const Text('Close Cycle'),
          ),
        ],
      ),
    );
  }

  void _showEditZoneDialog(Zone zone) {
    final nameController = TextEditingController(text: zone.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Zone'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Zone Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a zone name'),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
                return;
              }

              try {
                await ref.read(zoneRepositoryProvider).updateZone(zone.id, nameController.text.trim());
                ref.invalidate(zonesListProvider);
                
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zone updated successfully'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteZoneDialog(Zone zone) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text(
          'Are you sure you want to delete "${zone.name}"?\n\nNote: This will fail if there are customers assigned to this zone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(zoneRepositoryProvider).deleteZone(zone.id);
                ref.invalidate(zonesListProvider);
                
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zone deleted successfully'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesListProvider);
    final cyclesAsync = ref.watch(cyclesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'System Settings',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ResponsiveWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Registration Fee Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REGISTRATION FEE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _regFeeController,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.adminTextColor),
                      decoration: InputDecoration(
                        labelText: 'Fee Amount',
                        labelStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                        hintText: '0.00',
                        prefixText: 'GHC ',
                        filled: true,
                        fillColor: AppTheme.adminInputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (_regFeeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter fee amount')),
                          );
                          return;
                        }

                        try {
                          final fee = double.tryParse(_regFeeController.text);
                          if (fee == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid number')),
                            );
                            return;
                          }
                          await ref.read(settingsRepositoryProvider).setRegistrationFee(fee);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Registration fee set to GHC ${fee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                backgroundColor: AppTheme.adminAccentRevenue,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _regFeeController.clear();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                backgroundColor: AppTheme.adminAccentAlert,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: AppTheme.adminPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('UPDATE FEE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Business Cycles Card ──────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BUSINESS CYCLES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showCreateCycleDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: const Text('New Cycle', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.adminPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    cyclesAsync.when(
                      data: (cycles) {
                        if (cycles.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No cycles yet', style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: cycles.map((cycle) {
                            final isActive = cycle.isActive;
                            final isClosed = !isActive && cycle.endedAt != null;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.adminAccentRevenue.withOpacity(0.08)
                                    : AppTheme.adminInputFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.adminAccentRevenue.withOpacity(0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.play_circle_filled_rounded
                                        : isClosed
                                            ? Icons.lock_rounded
                                            : Icons.circle_outlined,
                                    color: isActive
                                        ? AppTheme.adminAccentRevenue
                                        : Colors.grey.shade400,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cycle.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: isActive
                                                ? AppTheme.adminTextColor
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? AppTheme.adminAccentRevenue
                                                    : isClosed
                                                        ? Colors.grey.shade400
                                                        : Colors.orange.shade300,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isActive ? 'ACTIVE' : isClosed ? 'CLOSED' : 'INACTIVE',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Actions
                                  if (!isActive && !isClosed)
                                    TextButton(
                                      onPressed: () async {
                                        try {
                                          await ref
                                              .read(cycleRepositoryProvider)
                                              .setActiveCycle(cycle.id);
                                          ref.invalidate(cyclesListProvider);
                                          ref.invalidate(activeCycleProvider);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('"${cycle.name}" is now active'),
                                                backgroundColor: AppTheme.adminAccentRevenue,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                                backgroundColor: AppTheme.adminAccentAlert,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.adminPrimaryColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: const Text('Activate', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  if (isActive)
                                    TextButton(
                                      onPressed: () => _showCloseCycleDialog(cycle),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.adminAccentAlert,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.adminAccentAlert)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manage Zones Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Zones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _zoneController,
                            decoration: const InputDecoration(
                              labelText: 'Zone Name',
                              hintText: 'Enter zone name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (_zoneController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter zone name')),
                              );
                              return;
                            }

                            try {
                              final zoneRepo = ref.read(zoneRepositoryProvider);
                              await zoneRepo.createZone(_zoneController.text.trim());
                              ref.invalidate(zonesListProvider);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Zone "${_zoneController.text}" added'),
                                    backgroundColor: AppTheme.secondaryColor,
                                  ),
                                );
                                _zoneController.clear();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppTheme.dangerColor,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    zonesAsync.when(
                      data: (zones) {
                        if (zones.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No zones yet', style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: zones.map((zone) {
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                              title: Text(zone.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              contentPadding: EdgeInsets.zero,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditZoneDialog(zone),
                                    tooltip: 'Edit',
                                    color: AppTheme.primaryColor,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _showDeleteZoneDialog(zone),
                                    tooltip: 'Delete',
                                    color: AppTheme.dangerColor,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('LOGOUT SYSTEM ADMIN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminAccentAlert,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
