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

import 'package:geolocator/geolocator.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isCheckedIn = false;
  bool _isCompletedToday = false;
  bool _isWithinGeofence = true;
  String _statusMessage = "Not checked in today";
  String _timeString = "--:--";
  String _checkOutTimeString = "--:--";

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
    if (_isCompletedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already completed your attendance punch in and out for today.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in at $_timeString (${_isWithinGeofence ? "In Office Radius" : "Outside Geofence"})'),
          backgroundColor: _isWithinGeofence ? AppTheme.primaryColor : Colors.orange.shade800,
        ),
      );
    } else {
      final now = DateTime.now();
      final outTimeFormatted = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      await attendanceService.checkOut(user.uid, org.organizationId);

      if (!mounted) return;
      setState(() {
        _isCheckedIn = false;
        _isCompletedToday = true;
        _checkOutTimeString = outTimeFormatted;
        _statusMessage = "Attendance completed for today";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked out at $outTimeFormatted. Attendance completed for today!'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

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

  Widget _buildSelectedTabBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return const EmployeeDirectoryScreen(key: PageStorageKey('admin_directory'), hideAppBar: true);
      case 2:
        return const GeofenceAuditScreen(key: PageStorageKey('admin_geofence'), hideAppBar: true);
      case 3:
        return const AuditLogsScreen(key: PageStorageKey('admin_logs'), hideAppBar: true);
      case 4:
        return const ProfileScreen(key: PageStorageKey('admin_profile'), hideAppBar: true);
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      key: const PageStorageKey('admin_home_overview'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Personal Attendance Check-In Punch Card for Admin
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
                        color: _isCompletedToday
                            ? Colors.blueGrey.shade100
                            : _isCheckedIn
                                ? Colors.redAccent.shade100.withOpacity(0.2)
                                : AppTheme.secondaryColor.withOpacity(0.15),
                        border: Border.all(
                          color: _isCompletedToday
                              ? Colors.grey
                              : _isCheckedIn
                                  ? Colors.redAccent
                                  : AppTheme.secondaryColor,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _isCompletedToday
                              ? Icons.task_alt_rounded
                              : Icons.fingerprint_rounded,
                          size: 30,
                          color: _isCompletedToday
                              ? Colors.grey.shade700
                              : _isCheckedIn
                                  ? Colors.redAccent
                                  : AppTheme.secondaryColor,
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
                          _isCompletedToday
                              ? 'Attendance Completed'
                              : _isCheckedIn
                                  ? 'Checked In'
                                  : 'Personal Attendance Punch',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCompletedToday
                              ? 'Punched Out at $_checkOutTimeString (Done)'
                              : _statusMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCompletedToday
                                ? Colors.grey.shade700
                                : _isCheckedIn
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textSecondaryColor,
                            fontWeight: (_isCheckedIn || _isCompletedToday) ? FontWeight.bold : FontWeight.normal,
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
                    onPressed: _isCompletedToday ? null : _toggleCheckIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompletedToday
                          ? Colors.grey.shade400
                          : _isCheckedIn
                              ? Colors.redAccent
                              : AppTheme.secondaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(90, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text(
                      _isCompletedToday
                          ? 'Completed'
                          : _isCheckedIn
                              ? 'Check Out'
                              : 'Punch In',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                        'Turnout Rate: ${ref.watch(attendanceStatsProvider).attendancePercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${ref.watch(attendanceStatsProvider).totalPresent} / ${ref.watch(attendanceStatsProvider).totalStaff} Checked In',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ref.watch(attendanceStatsProvider).attendancePercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.secondaryColor,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceMetricCard(
                          title: 'On-Time',
                          value: '${ref.watch(attendanceStatsProvider).presentCount}',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF00C853),
                          bgColor: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceMetricCard(
                          title: 'Late Check-ins',
                          value: '${ref.watch(attendanceStatsProvider).lateCount}',
                          icon: Icons.access_time_rounded,
                          color: const Color(0xFFFFAB00),
                          bgColor: const Color(0xFFFFF8E1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceMetricCard(
                          title: 'On Leave/Absent',
                          value: '${ref.watch(attendanceStatsProvider).onLeaveOrAbsent}',
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

          // Department Breakdown Grid
          Text('Department Breakdown', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemCount: ref.watch(departmentStatsProvider).length,
            itemBuilder: (context, index) {
              final dept = ref.watch(departmentStatsProvider)[index];
              return Card(
                color: Colors.white,
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business_center_outlined, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dept.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${dept.count} Staff Members',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (dept.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: AppTheme.secondaryColor,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Admin Quick Tools Card List
          Text('Admin Operations', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildQuickToolTile(
            context,
            title: 'Employee Directory & Roles',
            subtitle: 'View staff list, change roles, update designations',
            icon: Icons.people_alt_outlined,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildQuickToolTile(
            context,
            title: 'Office Geofence & Location Audit',
            subtitle: 'Real-time check-in coordinates on OpenStreetMap',
            icon: Icons.map_outlined,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildQuickToolTile(
            context,
            title: 'Security & System Audit Logs',
            subtitle: 'Track admin changes, role promotions, and location edits',
            icon: Icons.security_rounded,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          _buildQuickToolTile(
            context,
            title: 'SaaS Plan & Billing',
            subtitle: 'Manage active plan subscription, upgrade seats, download invoices',
            icon: Icons.payments_outlined,
            onTap: () => context.push('/saas-billing'),
          ),
          _buildQuickToolTile(
            context,
            title: 'Workspace Settings',
            subtitle: 'Edit office location, geofence radius, and check-in hours',
            icon: Icons.tune_rounded,
            onTap: () => context.push('/workspace-settings'),
          ),
          const SizedBox(height: 24),

          // Company Notice Board Section for Admin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Company Announcements', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.add_comment_rounded, color: AppTheme.primaryColor),
                onPressed: () => _showPostNoticeModal(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ref.watch(noticeStreamProvider).when(
            data: (notices) {
              if (notices.isEmpty) {
                return const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No announcements posted yet.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                    ),
                  ),
                );
              }

              return Column(
                children: notices.map((notice) {
                  final isHigh = notice.priority == 'high';
                  final badgeColor = isHigh ? Colors.red : AppTheme.secondaryColor;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: isHigh ? const BorderSide(color: Colors.redAccent, width: 1.5) : BorderSide.none,
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
                              isHigh ? 'HIGH PRIORITY' : 'ANNOUNCEMENT',
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(notice.content, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('By ${notice.authorName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final todayAttendanceAsync = ref.watch(todayAttendanceStreamProvider);

    todayAttendanceAsync.whenData((records) {
      if (user != null) {
        bool found = false;
        for (final r in records) {
          if (r.userId == user.uid) {
            found = true;
            if (r.checkOutTime != null) {
              _isCompletedToday = true;
              _isCheckedIn = false;
              _checkOutTimeString = "${r.checkOutTime!.hour.toString().padLeft(2, '0')}:${r.checkOutTime!.minute.toString().padLeft(2, '0')}";
              _statusMessage = "Attendance completed for today";
            } else {
              _isCheckedIn = true;
              _isCompletedToday = false;
              _timeString = "${r.checkInTime.hour.toString().padLeft(2, '0')}:${r.checkInTime.minute.toString().padLeft(2, '0')}";
              final lateness = r.status == 'late' ? ' (Late)' : '';
              final geofenceStatus = r.isWithinGeofence ? ' [Inside Office]' : ' [Outside Office]';
              _statusMessage = "Checked In$lateness$geofenceStatus";
            }
            break;
          }
        }
        if (!found) {
          _isCheckedIn = false;
          _isCompletedToday = false;
          _statusMessage = "Not checked in today";
        }
      }
    });

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
      body: _buildSelectedTabBody(),
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

  Widget _buildQuickToolTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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
