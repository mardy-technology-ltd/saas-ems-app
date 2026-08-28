import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;
    final stats = ref.watch(attendanceStatsProvider);
    final departments = ref.watch(departmentStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
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
              color: AppTheme.primaryColor,
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${user?.displayName ?? "Admin"} (Owner)',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Workspace Invite Code', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text(
                                org?.inviteCode ?? 'N/A',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: Colors.white),
                            onPressed: () {
                              if (org?.inviteCode != null) {
                                Clipboard.setData(ClipboardData(text: org!.inviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invite Code copied to clipboard!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Attendance Overview Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Attendance Overview", style: Theme.of(context).textTheme.titleLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Turnout Rate: ${stats.attendancePercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${stats.totalPresent} / ${stats.totalStaff} Checked In',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stats.totalStaff > 0 ? (stats.totalPresent / stats.totalStaff) : 0.0,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceMetricCard(
                            title: 'Present Today',
                            value: '${stats.presentCount}',
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF00C853),
                            bgColor: const Color(0xFFE8F5E9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildAttendanceMetricCard(
                            title: 'Late Check-ins',
                            value: '${stats.lateCount}',
                            icon: Icons.access_time_rounded,
                            color: const Color(0xFFFFAB00),
                            bgColor: const Color(0xFFFFF8E1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildAttendanceMetricCard(
                            title: 'On Leave/Absent',
                            value: '${stats.onLeaveOrAbsent}',
                            icon: Icons.event_busy_rounded,
                            color: const Color(0xFFFF1744),
                            bgColor: const Color(0xFFFFEBEE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Department Breakdown Section
            Text('Department Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: departments.map((dept) {
                    Color deptColor = Colors.blue;
                    IconData deptIcon = Icons.business_center_outlined;

                    if (dept.name == 'Engineering') {
                      deptColor = const Color(0xFF3F51B5);
                      deptIcon = Icons.developer_mode_rounded;
                    } else if (dept.name == 'HR') {
                      deptColor = const Color(0xFF009688);
                      deptIcon = Icons.people_outline_rounded;
                    } else if (dept.name == 'Sales') {
                      deptColor = const Color(0xFFFF9800);
                      deptIcon = Icons.trending_up_rounded;
                    } else if (dept.name == 'Accounts') {
                      deptColor = const Color(0xFF9C27B0);
                      deptIcon = Icons.account_balance_wallet_outlined;
                    } else if (dept.name == 'Management') {
                      deptColor = const Color(0xFF607D8B);
                      deptIcon = Icons.admin_panel_settings_outlined;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(deptIcon, size: 18, color: deptColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    dept.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Text(
                                '${dept.count} Staff (${dept.percentage.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: dept.percentage / 100,
                              minHeight: 6,
                              backgroundColor: deptColor.withValues(alpha: 0.1),
                              color: deptColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Quick Statistics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Active Staff',
                    value: '${stats.totalStaff}',
                    icon: Icons.people_rounded,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'SaaS Plan',
                    value: 'Free Tier',
                    icon: Icons.star_rounded,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Administrative Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              title: 'Employee Directory',
              subtitle: 'Add, suspend, or update employee records',
              icon: Icons.folder_shared_outlined,
              onTap: () => context.push('/employee-directory'),
            ),
            _buildActionItem(
              context,
              title: 'SaaS Billing & Upgrade',
              subtitle: 'Change your subscription plan & payment details',
              icon: Icons.payments_outlined,
              onTap: () {},
            ),
            _buildActionItem(
              context,
              title: 'Workspace Settings',
              subtitle: 'Configure company working hours & GPS geofencing radius',
              icon: Icons.tune_rounded,
              onTap: () => context.push('/workspace-settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
