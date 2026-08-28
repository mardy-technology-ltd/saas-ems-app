import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/attendance_controller.dart';

class EmployeeDashboard extends ConsumerStatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  ConsumerState<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboard> {
  bool _isCheckedIn = false;
  String _statusMessage = "Not checked in today";
  String _timeString = "--:--";

  void _toggleCheckIn() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    if (user == null || org == null) return;

    final attendanceService = ref.read(attendanceServiceProvider);

    if (!_isCheckedIn) {
      final now = DateTime.now();
      final timeFormatted = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      
      final record = await attendanceService.checkIn(
        user.uid,
        user.displayName,
        org.organizationId,
        checkInStartHour: org.checkInStartHour ?? "09:00",
      );

      setState(() {
        _isCheckedIn = true;
        _statusMessage = record.status == 'late' ? "Checked In (Late)" : "Checked In successfully";
        _timeString = timeFormatted;
      });
    } else {
      await attendanceService.checkOut(user.uid, org.organizationId);

      setState(() {
        _isCheckedIn = false;
        _statusMessage = "Checked Out successfully";
        _timeString = "--:--";
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCheckedIn ? 'Checked in successfully at $_timeString' : 'Checked out successfully'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final org = authState.organization;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
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
                    const Text(
                      'Attendance Check-In',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isCheckedIn ? AppTheme.secondaryColor : AppTheme.textSecondaryColor,
                        fontWeight: _isCheckedIn ? FontWeight.bold : FontWeight.normal,
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
                      onTap: _toggleCheckIn,
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCheckedIn ? Colors.redAccent.shade100.withValues(alpha: 0.2) : AppTheme.secondaryColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fingerprint_rounded,
                                size: 40,
                                color: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isCheckedIn ? 'Check Out' : 'Check In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isCheckedIn ? Colors.redAccent : AppTheme.secondaryColor,
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

            Text('My Operations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              title: 'Apply for Leave',
              subtitle: 'Submit requests for sick, annual, or casual leaves',
              icon: Icons.calendar_today_outlined,
              onTap: () {},
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
