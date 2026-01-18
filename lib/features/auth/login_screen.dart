import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../data/models/profile.dart';
import '../admin/navigation/admin_nav_shell.dart';
import '../agent/navigation/agent_nav_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _userType = 0; // 0: FIELD AGENT, 1: SYSTEM ADMIN (just for UI toggle)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final profile = await authRepo.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Check if agent is active
      if (profile.role == UserRole.agent && !profile.isActive) {
        await authRepo.signOut();
        _showError('Your account is pending admin approval');
        return;
      }

      // Navigate based on the user's actual role from database
      if (profile.role == UserRole.admin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminNavShell()),
        );
      } else if (profile.role == UserRole.agent) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AgentNavShell()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  void _showSignUpDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sign Up as Agent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your account will be reviewed by an admin before activation.',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimum 6 characters',
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (fullNameController.text.trim().isEmpty ||
                          emailController.text.trim().isEmpty ||
                          passwordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.signUp(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          fullName: fullNameController.text.trim(),
                        );

                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }

                        if (this.context.mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Account created! Please wait for admin approval.'),
                              backgroundColor: AppTheme.secondaryColor,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        if (this.context.mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: AppTheme.dangerColor,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.agentPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_rounded, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Segmented Control (visual only - actual role comes from DB)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildToggleItem('FIELD AGENT', 0),
                    ),
                    Expanded(
                      child: _buildToggleItem('SYSTEM ADMIN', 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
                enabled: !_isLoading,
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userType == 0 ? AppTheme.agentPrimaryColor : AppTheme.adminPrimaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('ACCESS PORTAL'),
              ),
              
              const SizedBox(height: 16),
              
              // Sign Up Link
              TextButton(
                onPressed: _isLoading ? null : _showSignUpDialog,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New Agent? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'Sign Up Here',
                      style: TextStyle(
                        color: AppTheme.agentPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(String label, int index) {
    final isActive = _userType == index;
    return GestureDetector(
      onTap: () => setState(() => _userType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
