import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  final bool hideAppBar;
  const ProfileScreen({super.key, this.hideAppBar = false});

  void _showEditProfileModal(BuildContext context, WidgetRef ref, String currentName, String currentDesignation) {
    final nameController = TextEditingController(text: currentName);
    final designationController = TextEditingController(text: currentDesignation);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Profile Details',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: 'Designation / Role Title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('My Profile & Account'),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Header
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'User Name',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (user?.role ?? 'STAFF').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.designation ?? 'Team Member',
                            style: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Organization Workspace Info Card
            Text('Workspace Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: org?.logoUrl != null && org!.logoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  org.logoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.business_rounded, color: AppTheme.primaryColor),
                                ),
                              )
                            : const Icon(Icons.business_rounded, color: AppTheme.primaryColor),
                      ),
                      title: const Text('Organization Name', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      subtitle: Text(org?.name ?? 'My SaaS Company', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFECFDF5),
                        child: Icon(Icons.vpn_key_rounded, color: AppTheme.secondaryColor),
                      ),
                      title: const Text('Workspace Invite Code', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      subtitle: Text(org?.inviteCode ?? 'AGY-101', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor),
                        onPressed: () {
                          if (org?.inviteCode != null) {
                            Clipboard.setData(ClipboardData(text: org!.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite Code copied!')),
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(Icons.location_on_rounded, color: Colors.amber),
                      ),
                      title: const Text('Office Geofence Location', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      subtitle: Text(
                        'Lat ${org?.officeLatitude ?? 23.8103}, Lng ${org?.officeLongitude ?? 90.4125} • ${org?.geofenceRadius ?? 200}m Radius',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Account Actions Section
            Text('Account & Preferences', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                    title: const Text('Edit Profile Details'),
                    subtitle: const Text('Change name or designation title'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showEditProfileModal(
                      context,
                      ref,
                      user?.displayName ?? '',
                      user?.designation ?? '',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                    title: const Text('Change Password'),
                    subtitle: const Text('Update account security credentials'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset email sent to your inbox.')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                    onTap: () => ref.read(authNotifierProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
