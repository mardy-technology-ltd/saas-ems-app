import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/notice_controller.dart';

class HRDashboard extends ConsumerWidget {
  const HRDashboard({super.key});

  void _showCreateNoticeDialog(BuildContext context, WidgetRef ref, String orgId, String authorName) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = 'normal';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Post Announcement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Office Holiday Notice'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Content', hintText: 'Enter notice details...'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Priority: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected: selectedPriority == 'normal',
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedPriority = 'normal');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('High'),
                        selectedColor: Colors.redAccent.shade100,
                        selected: selectedPriority == 'high',
                        onSelected: (val) {
                          if (val) setDialogState(() => selectedPriority = 'high');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    await ref.read(noticeServiceProvider).postNotice(
                      titleController.text.trim(),
                      contentController.text.trim(),
                      selectedPriority,
                      orgId,
                      authorName,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notice posted successfully!')),
                      );
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;
    final noticesAsync = ref.watch(noticeStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('HR Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            Card(
              color: AppTheme.secondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org?.name ?? 'My SaaS Workspace',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${user?.displayName ?? "HR Team"}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Role: ${user?.designation ?? "HR Lead"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Operations Today', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/leave-management'),
                    child: _buildStatCard(
                      context,
                      title: 'Pending Leaves',
                      value: '3 Requests',
                      icon: Icons.time_to_leave_rounded,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/geofence-audit'),
                    child: _buildStatCard(
                      context,
                      title: 'Absent Today',
                      value: '2 Staff',
                      icon: Icons.no_accounts_rounded,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Company Notice Board Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Company Notice Board', style: Theme.of(context).textTheme.titleLarge),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add_comment_rounded, size: 20),
                  onPressed: () {
                    if (org != null) {
                      _showCreateNoticeDialog(context, ref, org.organizationId, user?.displayName ?? 'HR Lead');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            noticesAsync.when(
              data: (notices) {
                if (notices.isEmpty) {
                  return const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No announcements posted.',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: notices.map((notice) {
                    final isHighPriority = notice.priority == 'high';
                    final badgeColor = isHighPriority ? Colors.red : AppTheme.secondaryColor;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighPriority
                            ? const BorderSide(color: Colors.redAccent, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHighPriority ? 'HIGH PRIORITY' : 'ANNOUNCEMENT',
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notice.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notice.content,
                              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'By ${notice.authorName}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${notice.createdAt.day}/${notice.createdAt.month}/${notice.createdAt.year}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading notices: $e', style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 24),

            Text('HR Management Tools', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              title: 'Verify Attendance',
              subtitle: 'View check-in times and locations of employees',
              icon: Icons.verified_user_outlined,
              onTap: () => context.push('/geofence-audit'),
            ),
            _buildActionItem(
              context,
              title: 'Leave Approvals',
              subtitle: 'Approve, reject, or comment on time-off submissions',
              icon: Icons.calendar_today_outlined,
              onTap: () => context.push('/leave-management'),
            ),
            _buildActionItem(
              context,
              title: 'Employee Directory',
              subtitle: 'Manage roles, designations, and view member profiles',
              icon: Icons.badge_outlined,
              onTap: () => context.push('/employee-directory'),
            ),
            _buildActionItem(
              context,
              title: 'Payroll Dashboard',
              subtitle: 'Calculate salary, benefits, and email monthly payslips',
              icon: Icons.wallet_outlined,
              onTap: () => context.push('/saas-billing'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.secondaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

