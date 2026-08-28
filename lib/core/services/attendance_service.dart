import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String organizationId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // 'present', 'late', 'absent', 'leave'
  final double? latitude;
  final double? longitude;
  final bool isWithinGeofence;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.organizationId,
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.latitude,
    this.longitude,
    this.isWithinGeofence = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'organizationId': organizationId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'isWithinGeofence': isWithinGeofence,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Employee',
      organizationId: map['organizationId'] ?? '',
      checkInTime: DateTime.tryParse(map['checkInTime'] ?? '') ?? DateTime.now(),
      checkOutTime: map['checkOutTime'] != null ? DateTime.tryParse(map['checkOutTime']) : null,
      status: map['status'] ?? 'present',
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isWithinGeofence: map['isWithinGeofence'] ?? true,
    );
  }
}

class AttendanceService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AttendanceService(this._authService);

  bool get _useFirebase => _authService.isFirebaseInitialized;

  // In-memory mock database of attendance records for prototype testing
  static final List<AttendanceRecord> _mockRecords = [
    AttendanceRecord(
      id: 'mock_att_1',
      userId: 'mock_admin',
      userName: 'Admin Owner',
      organizationId: 'mock_org_1',
      checkInTime: DateTime.now().copyWith(hour: 8, minute: 45),
      status: 'present',
      latitude: 23.8103,
      longitude: 90.4125,
      isWithinGeofence: true,
    ),
    AttendanceRecord(
      id: 'mock_att_2',
      userId: 'mock_hr',
      userName: 'HR Manager',
      organizationId: 'mock_org_1',
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 25), // Late
      status: 'late',
      latitude: 23.8115,
      longitude: 90.4132,
      isWithinGeofence: true,
    ),
    AttendanceRecord(
      id: 'mock_att_3',
      userId: 'mock_emp1',
      userName: 'Rahim Ahmed',
      organizationId: 'mock_org_1',
      checkInTime: DateTime.now().copyWith(hour: 8, minute: 55),
      status: 'present',
      latitude: 23.8200, // Slightly further away
      longitude: 90.4250,
      isWithinGeofence: false,
    ),
    AttendanceRecord(
      id: 'mock_att_4',
      userId: 'mock_emp2',
      userName: 'Tanvir Hasan',
      organizationId: 'mock_org_1',
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 05),
      status: 'late',
      latitude: 23.8105,
      longitude: 90.4128,
      isWithinGeofence: true,
    ),
  ];

  // Stream today's attendance records for an organization
  Stream<List<AttendanceRecord>> streamTodayAttendance(String organizationId) {
    if (_useFirebase) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      return _firestore
          .collection('attendance')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data()))
            .where((rec) => rec.checkInTime.isAfter(startOfDay))
            .toList();
      });
    }

    // Mock Stream fallback
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return _mockRecords.where((rec) => rec.organizationId == organizationId).toList();
    });
  }

  // Check In method
  Future<AttendanceRecord> checkIn(
    String userId,
    String userName,
    String organizationId, {
    String checkInStartHour = "09:00",
  }) async {
    final now = DateTime.now();

    // Determine status (late vs present)
    final timeParts = checkInStartHour.split(":");
    final startHour = int.tryParse(timeParts[0]) ?? 9;
    final startMinute = int.tryParse(timeParts.length > 1 ? timeParts[1] : "0") ?? 0;

    final targetDeadline = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final status = now.isAfter(targetDeadline) ? 'late' : 'present';

    final id = _useFirebase
        ? _firestore.collection('attendance').doc().id
        : "mock_att_${now.millisecondsSinceEpoch}";

    final record = AttendanceRecord(
      id: id,
      userId: userId,
      userName: userName,
      organizationId: organizationId,
      checkInTime: now,
      status: status,
    );

    if (_useFirebase) {
      try {
        await _firestore.collection('attendance').doc(id).set(record.toMap());
      } catch (e) {
        debugPrint("Firebase CheckIn Error: $e");
      }
    }

    // Update local mock list
    _mockRecords.removeWhere((r) => r.userId == userId);
    _mockRecords.add(record);

    return record;
  }

  // Check Out method
  Future<void> checkOut(String userId, String organizationId) async {
    final now = DateTime.now();

    if (_useFirebase) {
      try {
        final query = await _firestore
            .collection('attendance')
            .where('userId', isEqualTo: userId)
            .where('organizationId', isEqualTo: organizationId)
            .get();

        if (query.docs.isNotEmpty) {
          final docId = query.docs.last.id;
          await _firestore.collection('attendance').doc(docId).update({
            'checkOutTime': now.toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint("Firebase CheckOut Error: $e");
      }
    }

    // Mock update
    final index = _mockRecords.indexWhere((r) => r.userId == userId);
    if (index != -1) {
      final existing = _mockRecords[index];
      _mockRecords[index] = AttendanceRecord(
        id: existing.id,
        userId: existing.userId,
        userName: existing.userName,
        organizationId: existing.organizationId,
        checkInTime: existing.checkInTime,
        checkOutTime: now,
        status: existing.status,
      );
    }
  }
}
