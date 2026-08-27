import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authNotifierProvider.notifier).signIn(
            _emailController.text,
            _passwordController.text,
          );
      if (!mounted) return;
      if (success) {
        // GoRouter redirect logic will automatically take them to the correct dashboard/workspace setup
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Login failed. Please check credentials.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _fillMock(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'password';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 70,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Login to manage your workspace',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (authState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Login'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'Demo Mocks (Click to Fill):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Admin'),
                    onPressed: () => _fillMock('admin@ems.com'),
                  ),
                  ActionChip(
                    label: const Text('HR'),
                    onPressed: () => _fillMock('hr@ems.com'),
                  ),
                  ActionChip(
                    label: const Text('Employee'),
                    onPressed: () => _fillMock('employee@ems.com'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
