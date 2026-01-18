import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import '../../../providers/admin_providers.dart';

class ZoneManagementScreen extends ConsumerStatefulWidget {
  const ZoneManagementScreen({super.key});

  @override
  ConsumerState<ZoneManagementScreen> createState() => _ZoneManagementScreenState();
}

class _ZoneManagementScreenState extends ConsumerState<ZoneManagementScreen> {
  void _showAddZoneDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Zone'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Zone Name',
            hintText: 'Enter zone name',
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
                await ref.read(zoneRepositoryProvider).createZone(nameController.text.trim());
                
                // Refresh zones list
                ref.invalidate(zonesListProvider);
                
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zone created successfully'),
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditZoneDialog(int zoneId, String currentName) {
    final nameController = TextEditingController(text: currentName);

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
                await ref.read(zoneRepositoryProvider).updateZone(zoneId, nameController.text.trim());
                
                // Refresh zones list
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

  void _showDeleteConfirmDialog(int zoneId, String zoneName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Are you sure you want to delete "$zoneName"?\n\nNote: This will fail if there are customers assigned to this zone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(zoneRepositoryProvider).deleteZone(zoneId);
                
                // Refresh zones list
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

    return Scaffold(
      backgroundColor: AppTheme.adminBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Zone Management',
          style: TextStyle(
            color: AppTheme.adminTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: zonesAsync.when(
        data: (zones) {
          if (zones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'No zones defined yet',
                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddZoneDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('ADD FIRST ZONE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final zone = zones[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.adminPrimaryColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppTheme.adminPrimaryColor, size: 24),
                  ),
                  title: Text(
                    zone.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.adminTextColor),
                  ),
                  subtitle: Text(
                    'ZONE ID: ${zone.id}',
                    style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppTheme.adminPrimaryColor, size: 28),
                        onPressed: () => _showEditZoneDialog(zone.id, zone.name),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.adminAccentAlert, size: 22),
                        onPressed: () => _showDeleteConfirmDialog(zone.id, zone.name),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
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
                onPressed: () => ref.refresh(zonesListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddZoneDialog,
        backgroundColor: AppTheme.adminPrimaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ADD ZONE', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }
}
