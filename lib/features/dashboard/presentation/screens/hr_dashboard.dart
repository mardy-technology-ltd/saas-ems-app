import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notice_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../directory/presentation/screens/employee_directory_screen.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/notice_controller.dart';
import 'geofence_audit_screen.dart';
import 'leave_management_screen.dart';

class HRDashboard extends ConsumerStatefulWidget {
  const HRDashboard({super.key});

  @override
  ConsumerState<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends ConsumerState<HRDashboard> {
  int _selectedIndex = 0;
  bool _isCheckedIn = false;
  bool _isWithinGeofence = true;
  String _statusMessage = "Not checked in today";
  String _timeString = "--:--";

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  void _toggleCheckIn() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    if (user == null || org == null) return;

    final attendanceService = ref.read(attendanceServiceProvider);

    if (!_isCheckedIn) {
      final now = DateTime.now();
      final timeFormatted = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      
      final position = await _getCurrentLocation();

      final record = await attendanceService.checkIn(
        user.uid,
        user.displayName,
        org.organizationId,
        checkInStartHour: org.checkInStartHour ?? "09:00",
        latitude: position?.latitude,
        longitude: position?.longitude,
        officeLat: org.officeLatitude,
        officeLng: org.officeLongitude,
        geofenceRadius: org.geofenceRadius,
      );

      if (!mounted) return;
      setState(() {
        _isCheckedIn = true;
        _isWithinGeofence = record.isWithinGeofence;
        final lateness = record.status == 'late' ? ' (Late)' : '';
        final geofenceStatus = record.isWithinGeofence ? ' [Inside Office]' : ' [Outside Office]';
        _statusMessage = "Checked In$lateness$geofenceStatus";
        _timeString = timeFormatted;
      });
    } else {
      await attendanceService.checkOut(user.uid, org.organizationId);

      if (!mounted) return;
      setState(() {
        _isCheckedIn = false;
        _statusMessage = "Checked Out successfully";
        _timeString = "--:--";
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCheckedIn 
            ? 'Checked in at $_timeString (${_isWithinGeofence ? "In Office Radius" : "Outside Geofence"})' 
            : 'Checked out successfully'),
        backgroundColor: _isWithinGeofence ? AppTheme.primaryColor : Colors.orange.shade800,
      ),
    );
  }

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

  Widget _buildOverviewTab(UserModel? user, OrganizationModel? org, AsyncValue<List<NoticeModel>> noticesAsync) {
    return SingleChildScrollView(
      key: const PageStorageKey('hr_home_overview'),
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
          const SizedBox(height: 16),

          // Personal Attendance Check-In Section for HR
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleCheckIn,
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCheckedIn ? Colors.redAccent.shade100.withOpacity(0.2) : AppTheme.secondaryColor.withOpacity(0.15),
                        border: Border.all(
                          color: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 32,
                          color: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCheckedIn ? 'Checked In' : 'Attendance Check-In',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCheckedIn ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
                            fontWeight: _isCheckedIn ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (_isCheckedIn)
                          Text(
                            'Time: $_timeString',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _toggleCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
                      minimumSize: const Size(90, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(_isCheckedIn ? 'Check Out' : 'Punch In'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Operations Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
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
                  onTap: () => setState(() => _selectedIndex = 3),
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
              IconButton(
                icon: const Icon(Icons.add_comment_rounded, color: AppTheme.primaryColor),
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
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          _buildActionItem(
            context,
            title: 'Leave Approvals',
            subtitle: 'Approve, reject, or comment on time-off submissions',
            icon: Icons.calendar_today_outlined,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildActionItem(
            context,
            title: 'Employee Directory',
            subtitle: 'Manage roles, designations, and view member profiles',
            icon: Icons.badge_outlined,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildActionItem(
            context,
            title: 'Payroll & Compensation',
            subtitle: 'View staff payroll & compensation summaries',
            icon: Icons.wallet_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SaaS Subscription & Billing is managed by Workspace Admin.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabBody(UserModel? user, OrganizationModel? org, AsyncValue<List<NoticeModel>> noticesAsync) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(user, org, noticesAsync);
      case 1:
        return const LeaveManagementScreen(key: PageStorageKey('hr_leaves'), hideAppBar: true);
      case 2:
        return const EmployeeDirectoryScreen(key: PageStorageKey('hr_directory'), hideAppBar: true);
      case 3:
        return const GeofenceAuditScreen(key: PageStorageKey('hr_attendance'), hideAppBar: true);
      case 4:
        return const ProfileScreen(key: PageStorageKey('hr_profile'), hideAppBar: true);
      default:
        return _buildOverviewTab(user, org, noticesAsync);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;
    final noticesAsync = ref.watch(noticeStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'HR Portal'
              : _selectedIndex == 1
                  ? 'Leave Approvals'
                  : _selectedIndex == 2
                      ? 'Employee Directory'
                      : _selectedIndex == 3
                          ? 'Attendance Geofence'
                          : 'My Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: _buildSelectedTabBody(user, org, noticesAsync),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Leaves',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Directory',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'Attendance',
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
          backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
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
