import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            accountName: Text(
              user?.displayName ?? 'User Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user?.email ?? '', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (user?.role ?? 'STAFF').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        org?.name ?? 'SaaS Company',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          // Workspace Invite Code Banner
          if (org?.inviteCode != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite Code',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                      ),
                      Text(
                        org!.inviteCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primaryColor),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: org.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    if (user?.role == 'admin') {
                      context.go('/admin-dashboard');
                    } else if (user?.role == 'hr') {
                      context.go('/hr-dashboard');
                    } else {
                      context.go('/employee-dashboard');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_alt_rounded, color: AppTheme.primaryColor),
                  title: const Text('Employee Directory'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/employee-directory');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_rounded, color: AppTheme.primaryColor),
                  title: const Text('Geofence Audit Log'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/geofence-audit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppTheme.primaryColor),
                  title: const Text('Security Activity Logs'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/audit-logs');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments_rounded, color: AppTheme.primaryColor),
                  title: const Text('SaaS Billing & Upgrade'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/saas-billing');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                  title: const Text('Workspace Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/workspace-settings');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                  title: const Text('My Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
              ],
            ),
          ),

          // Footer Sign Out
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
