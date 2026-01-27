import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/providers.dart';
import'../../../providers/agent_providers.dart';
import '../../../providers/admin_providers.dart';
import '../../../providers/auth_provider.dart';

class NewRegistrationScreen extends ConsumerStatefulWidget {
  const NewRegistrationScreen({super.key});

  @override
  ConsumerState<NewRegistrationScreen> createState() => _NewRegistrationScreenState();
}

class _NewRegistrationScreenState extends ConsumerState<NewRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int? _selectedZoneId;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a zone')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final currentUser = await ref.read(currentUserProvider.future);

      if (currentUser == null) {
        throw Exception('Not logged in');
      }

      // Create customer without product (product added separately later)
      // Registration fee is 0 initially because it's calculated per product assigned
      await customerRepo.createCustomer(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        zoneId: _selectedZoneId!,
        assignedAgentId: currentUser.id,
        registrationFeePaid: 0,
      );

      if (mounted) {
        // Clear form
        _fullNameController.clear();
        _phoneController.clear();
        setState(() {
          _selectedZoneId = null;
        });

        // Refresh customer list (both agent and admin views)
        ref.invalidate(assignedCustomersProvider);
        ref.invalidate(allCustomersProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer registered successfully!'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(zonesProvider);

    return Scaffold(
      backgroundColor: AppTheme.agentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Registration',
          style: TextStyle(
            color: AppTheme.agentTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.agentTextColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter customer name',
                icon: Icons.person_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '024 XXXXXXX',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Assignment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.agentTextColor,
                ),
              ),
              const SizedBox(height: 16),

              // Zone Dropdown
              zonesAsync.when(
                data: (zones) {
                  if (zones.isEmpty) {
                    return _buildErrorState('No zones available. Admin needs to add zones.');
                  }
                  
                  return _buildDropdownField<int>(
                    value: _selectedZoneId,
                    label: 'Zone',
                    hint: 'Select zone',
                    icon: Icons.map_rounded,
                    items: zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone.id,
                        child: Text(zone.name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedZoneId = value),
                    validator: (value) => value == null ? 'Please select a zone' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(color: AppTheme.agentPrimaryColor),
                error: (error, _) => Text('Error: $error'),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.agentPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'REGISTER CUSTOMER',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.agentTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.agentTextColor.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: AppTheme.agentPrimaryColor, size: 20),
            filled: true,
            fillColor: AppTheme.agentInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: _isLoading ? null : onChanged,
          validator: validator,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.agentTextColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.agentTextColor.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: AppTheme.agentPrimaryColor, size: 20),
            filled: true,
            fillColor: AppTheme.agentInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
