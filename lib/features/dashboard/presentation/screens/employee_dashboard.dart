import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/notice_controller.dart';
import 'leave_management_screen.dart';

class EmployeeDashboard extends ConsumerStatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  ConsumerState<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboard> {
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

  Widget _buildOverviewTab() {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    return SingleChildScrollView(
      key: const PageStorageKey('emp_home_overview'),
      padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile Card
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Employee Name',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            user?.designation ?? 'Role/Title',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.corporate_fare_outlined, size: 14, color: AppTheme.textSecondaryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  org?.name ?? 'Company name',
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Check In/Out Section
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      _isCompletedToday
                          ? 'Attendance Completed'
                          : _isCheckedIn
                              ? 'Checked In'
                              : 'Attendance Check-In',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCompletedToday
                          ? 'Punched Out at $_checkOutTimeString (Done for today)'
                          : _statusMessage,
                      style: TextStyle(
                        color: _isCompletedToday
                            ? Colors.grey.shade700
                            : _isCheckedIn
                                ? AppTheme.secondaryColor
                                : AppTheme.textSecondaryColor,
                        fontWeight: (_isCheckedIn || _isCompletedToday) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (_isCheckedIn) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Check-In time: $_timeString',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isCompletedToday ? null : _toggleCheckIn,
                      child: Container(
                        height: 120,
                        width: 120,
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
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCompletedToday
                                    ? Icons.task_alt_rounded
                                    : Icons.fingerprint_rounded,
                                size: 40,
                                color: _isCompletedToday
                                    ? Colors.grey.shade700
                                    : _isCheckedIn
                                        ? Colors.redAccent
                                        : AppTheme.secondaryColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isCompletedToday
                                    ? 'Completed'
                                    : _isCheckedIn
                                        ? 'Check Out'
                                        : 'Check In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCompletedToday
                                      ? Colors.grey.shade700
                                      : _isCheckedIn
                                          ? Colors.redAccent
                                          : AppTheme.secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Company Notice Board
            Text('Company Notice Board', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ref.watch(noticeStreamProvider).when(
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
            const SizedBox(height: 20),

            Text('My Operations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              title: 'Apply for Leave',
              subtitle: 'Submit requests for sick, annual, or casual leaves',
              icon: Icons.calendar_today_outlined,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            _buildActionItem(
              context,
              title: 'Assigned Tasks',
              subtitle: 'Check tasks assigned to you and update status',
              icon: Icons.assignment_turned_in_outlined,
              onTap: () {},
            ),
            _buildActionItem(
              context,
              title: 'My Payslips',
              subtitle: 'View and download monthly earnings details',
              icon: Icons.file_download_outlined,
              onTap: () {},
            ),
          ],
        ),
      );
    }
  Widget _buildSelectedTabBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return const LeaveManagementScreen(key: PageStorageKey('emp_leaves'), hideAppBar: true);
      case 2:
        return const ProfileScreen(key: PageStorageKey('emp_profile'), hideAppBar: true);
      default:
        return _buildOverviewTab();
    }
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Employee Dashboard'
              : _selectedIndex == 1
                  ? 'My Leave Dashboard'
                  : 'My Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Leaves',
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
