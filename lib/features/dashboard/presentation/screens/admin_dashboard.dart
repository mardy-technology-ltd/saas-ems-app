import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../directory/presentation/screens/employee_directory_screen.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/notice_controller.dart';
import 'geofence_audit_screen.dart';
import 'audit_logs_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  void _showPostNoticeModal(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String priority = 'normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    'Post Company Announcement',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title',
                      prefixIcon: Icon(Icons.campaign_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Details',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Priority Level',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('Normal Announcement'),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Text('🔴 High Priority / Urgent'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          priority = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter both title and details.')),
                        );
                        return;
                      }

                      final authState = ref.read(authNotifierProvider);
                      final user = authState.user;
                      final org = authState.organization;

                      if (org == null) return;

                      await ref.read(noticeServiceProvider).postNotice(
                            titleController.text.trim(),
                            contentController.text.trim(),
                            priority,
                            org.organizationId,
                            user?.displayName ?? 'Admin',
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Announcement posted successfully!'),
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Post Announcement'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(attendanceStatsProvider);
    final departments = ref.watch(departmentStatsProvider);
    final noticesAsync = ref.watch(noticeStreamProvider);

    final List<Widget> pages = [
      // Index 0: Main Dashboard Overview
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Attendance Overview Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Attendance Overview", style: Theme.of(context).textTheme.titleLarge),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.15),
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
                        value: (stats.totalStaff > 0 ? (stats.totalPresent / stats.totalStaff) : 0.0).clamp(0.0, 1.0),
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
                              value: (dept.percentage / 100).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: deptColor.withOpacity(0.1),
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

            // Company Notice Board Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Company Notice Board',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showPostNoticeModal(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Post Notice'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
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
                          'No announcements posted yet.',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: notices.map((notice) {
                    final isHighPriority = notice.priority == 'high';
                    final badgeColor = isHighPriority ? Colors.red : AppTheme.primaryColor;

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.15),
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
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                                  onPressed: () => ref.read(noticeServiceProvider).deleteNotice(notice.id),
                                ),
                              ],
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
                                  '${notice.createdAt.day}/${notice.createdAt.month}/${notice.createdAt.year} ${notice.createdAt.hour}:${notice.createdAt.minute.toString().padLeft(2, '0')}',
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
          ],
        ),
      ),

      // Index 1: Staff Directory View
      const EmployeeDirectoryScreen(hideAppBar: true),

      // Index 2: Geofence Audit View
      const GeofenceAuditScreen(hideAppBar: true),

      // Index 3: Activity Audit Logs View
      const AuditLogsScreen(hideAppBar: true),

      // Index 4: User Profile View
      const ProfileScreen(hideAppBar: true),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Admin Portal'
              : _selectedIndex == 1
                  ? 'Employee Directory'
                  : _selectedIndex == 2
                      ? 'Geofence Audit Log'
                      : _selectedIndex == 3
                          ? 'Activity Audit Logs'
                          : 'My Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Workspace Settings',
            onPressed: () => context.push('/workspace-settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Geofence',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security_rounded),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
