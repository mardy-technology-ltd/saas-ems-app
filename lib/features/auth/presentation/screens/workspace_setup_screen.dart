import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  ConsumerState<WorkspaceSetupScreen> createState() => _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends ConsumerState<WorkspaceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();

  void _submit(bool isAdmin) async {
    if (_formKey.currentState!.validate()) {
      bool success;
      if (isAdmin) {
        success = await ref.read(authNotifierProvider.notifier).createOrganization(
              _inputController.text,
            );
      } else {
        success = await ref.read(authNotifierProvider.notifier).joinOrganization(
              _inputController.text,
            );
      }

      if (!mounted) return;
      if (success) {
        // GoRouter redirect takes care of navigating to the right dashboard
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to setup workspace. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Workspace Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        isAdmin ? Icons.add_business_rounded : Icons.group_add_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAdmin ? 'Register Company Space' : 'Join a Company Space',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAdmin
                            ? 'Set up a new organization tenant to manage employees, payroll, and work tracking.'
                            : 'Enter the unique organization invite code shared by your HR/Admin to join their workspace.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          labelText: isAdmin ? 'Organization/Company Name' : 'Company Invite Code',
                          hintText: isAdmin ? 'e.g. Antigravity Soft Ltd' : 'e.g. AGY-101',
                          prefixIcon: Icon(isAdmin ? Icons.corporate_fare_outlined : Icons.vpn_key_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isAdmin ? 'Please enter company name' : 'Please enter invite code';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (authState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: () => _submit(isAdmin),
                          child: Text(isAdmin ? 'Create Organization' : 'Join Workspace'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
