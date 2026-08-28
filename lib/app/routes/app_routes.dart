import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/workspace_setup_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../../features/dashboard/presentation/screens/hr_dashboard.dart';
import '../../features/dashboard/presentation/screens/employee_dashboard.dart';
import '../../features/directory/presentation/screens/employee_directory_screen.dart';
import '../../features/directory/presentation/screens/workspace_settings_screen.dart';
import '../../features/dashboard/presentation/screens/saas_billing_screen.dart';
import '../../features/dashboard/presentation/screens/geofence_audit_screen.dart';
import '../../features/dashboard/presentation/screens/audit_logs_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/workspace-setup',
        builder: (context, state) => const WorkspaceSetupScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/hr-dashboard',
        builder: (context, state) => const HRDashboard(),
      ),
      GoRoute(
        path: '/employee-dashboard',
        builder: (context, state) => const EmployeeDashboard(),
      ),
      GoRoute(
        path: '/employee-directory',
        builder: (context, state) => const EmployeeDirectoryScreen(),
      ),
      GoRoute(
        path: '/workspace-settings',
        builder: (context, state) => const WorkspaceSettingsScreen(),
      ),
      GoRoute(
        path: '/saas-billing',
        builder: (context, state) => const SaaSBillingScreen(),
      ),
      GoRoute(
        path: '/geofence-audit',
        builder: (context, state) => const GeofenceAuditScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.user;
      final org = authState.organization;

      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isLoading) return isSplash ? null : '/splash';

      // User not logged in
      if (user == null) {
        if (isLoggingIn || isSigningUp || isOnboarding) return null;
        return '/onboarding';
      }

      // User is logged in but has no Organization
      if (org == null) {
        if (state.matchedLocation == '/workspace-setup') return null;
        return '/workspace-setup';
      }

      // User is logged in and has an Organization -> Dashboard redirection
      if (isSplash || isLoggingIn || isSigningUp || isOnboarding || state.matchedLocation == '/workspace-setup') {
        if (user.role == 'admin') return '/admin-dashboard';
        if (user.role == 'hr') return '/hr-dashboard';
        return '/employee-dashboard';
      }

      return null;
    },
  );
});
