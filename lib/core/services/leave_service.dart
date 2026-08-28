import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String leaveType; // Casual, Medical, Earned
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final String organizationId;
  final DateTime createdAt;

  LeaveRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.organizationId,
    required this.createdAt,
  });

  int get totalDays {
    final difference = endDate.difference(startDate).inDays + 1;
    return difference > 0 ? difference : 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'leaveType': leaveType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'status': status,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return LeaveRequestModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Employee',
      userRole: map['userRole'] ?? 'employee',
      leaveType: map['leaveType'] ?? 'Casual Leave',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['endDate']?.toString() ?? '') ?? DateTime.now(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'PENDING',
      organizationId: map['organizationId'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class LeaveService {
  static final List<LeaveRequestModel> _mockLeaves = [
    LeaveRequestModel(
      id: 'leave_1',
      userId: 'mock_emp',
      userName: 'Junayed',
      userRole: 'employee',
      leaveType: 'Casual Leave',
      startDate: DateTime.now().add(const Duration(days: 2)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      reason: 'Family urgent matter',
      status: 'PENDING',
      organizationId: 'mock_org_1',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    LeaveRequestModel(
      id: 'leave_2',
      userId: 'mock_hr',
      userName: 'Mardy',
      userRole: 'hr',
      leaveType: 'Medical Leave',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().subtract(const Duration(days: 4)),
      reason: 'Doctor appointment',
      status: 'APPROVED',
      organizationId: 'mock_org_1',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  bool get _isFirebaseInitialized {
    try {
      return FirebaseFirestore.instance.app.name.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<List<LeaveRequestModel>> streamLeaves(String organizationId) {
    if (_isFirebaseInitialized) {
      try {
        return FirebaseFirestore.instance
            .collection('leave_requests')
            .where('organizationId', isEqualTo: organizationId)
            .snapshots()
            .map((snapshot) {
          final list = snapshot.docs.map((doc) => LeaveRequestModel.fromMap(doc.data(), doc.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
      } catch (e) {
        debugPrint("Firebase streamLeaves error: $e. Fallback to mock.");
      }
    }

    return Stream.value(
      _mockLeaves.where((l) => l.organizationId == organizationId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<void> submitLeaveRequest({
    required String userId,
    required String userName,
    required String userRole,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String organizationId,
  }) async {
    final newId = 'leave_${DateTime.now().millisecondsSinceEpoch}';
    final request = LeaveRequestModel(
      id: newId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'PENDING',
      organizationId: organizationId,
      createdAt: DateTime.now(),
    );

    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('leave_requests').doc(newId).set(request.toMap());
        return;
      } catch (e) {
        debugPrint("Firebase submitLeaveRequest error: $e");
      }
    }

    _mockLeaves.insert(0, request);
  }

  Future<void> updateLeaveStatus(String leaveId, String newStatus) async {
    if (_isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('leave_requests').doc(leaveId).update({
          'status': newStatus,
        });
        return;
      } catch (e) {
        debugPrint("Firebase updateLeaveStatus error: $e");
      }
    }

    final index = _mockLeaves.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _mockLeaves[index];
      _mockLeaves[index] = LeaveRequestModel(
        id: old.id,
        userId: old.userId,
        userName: old.userName,
        userRole: old.userRole,
        leaveType: old.leaveType,
        startDate: old.startDate,
        endDate: old.endDate,
        reason: old.reason,
        status: newStatus,
        organizationId: old.organizationId,
        createdAt: old.createdAt,
      );
    }
  }
}

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService();
});
