import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/attendance_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../features/directory/presentation/controllers/directory_controller.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AttendanceService(authService);
});

final todayAttendanceStreamProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final org = ref.watch(authNotifierProvider).organization;
  if (org == null || org.organizationId.isEmpty) {
    return Stream.value([]);
  }
  final attendanceService = ref.watch(attendanceServiceProvider);
  return attendanceService.streamTodayAttendance(org.organizationId);
});

class AttendanceStats {
  final int totalStaff;
  final int presentCount;
  final int lateCount;
  final int totalPresent;
  final int onLeaveOrAbsent;
  final double attendancePercentage;

  AttendanceStats({
    required this.totalStaff,
    required this.presentCount,
    required this.lateCount,
    required this.totalPresent,
    required this.onLeaveOrAbsent,
    required this.attendancePercentage,
  });
}

final attendanceStatsProvider = Provider<AttendanceStats>((ref) {
  final attendanceAsync = ref.watch(todayAttendanceStreamProvider);
  final directoryAsync = ref.watch(directoryStreamProvider);

  final totalStaff = directoryAsync.maybeWhen(
    data: (users) => users.isEmpty ? 12 : users.length,
    orElse: () => 12,
  );

  final records = attendanceAsync.maybeWhen(
    data: (list) => list,
    orElse: () => <AttendanceRecord>[],
  );

  int present = 0;
  int late = 0;

  for (var r in records) {
    if (r.status == 'late') {
      late++;
    } else {
      present++;
    }
  }

  final totalPresent = present + late;
  final absent = (totalStaff - totalPresent).clamp(0, totalStaff);
  final percentage = totalStaff > 0 ? (totalPresent / totalStaff) * 100 : 0.0;

  return AttendanceStats(
    totalStaff: totalStaff,
    presentCount: present,
    lateCount: late,
    totalPresent: totalPresent,
    onLeaveOrAbsent: absent,
    attendancePercentage: percentage,
  );
});

class DepartmentItem {
  final String name;
  final int count;
  final double percentage;

  DepartmentItem({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

final departmentStatsProvider = Provider<List<DepartmentItem>>((ref) {
  final directoryAsync = ref.watch(directoryStreamProvider);

  final users = directoryAsync.maybeWhen(
    data: (list) => list,
    orElse: () => [],
  );

  if (users.isEmpty) return [];

  final Map<String, int> counts = {};
  for (var u in users) {
    final dept = u.department;
    counts[dept] = (counts[dept] ?? 0) + 1;
  }

  final total = users.length;
  final items = counts.entries.map((e) {
    return DepartmentItem(
      name: e.key,
      count: e.value,
      percentage: total > 0 ? (e.value / total) * 100 : 0.0,
    );
  }).toList();

  items.sort((a, b) => b.count.compareTo(a.count));
  return items;
});
