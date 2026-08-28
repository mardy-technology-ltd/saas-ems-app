import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class AuditLogModel {
  final String id;
  final String action;
  final String performedBy;
  final String details;
  final DateTime timestamp;
  final String category; // 'security', 'role', 'settings', 'notice'
  final String organizationId;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.details,
    required this.timestamp,
    required this.category,
    required this.organizationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'organizationId': organizationId,
    };
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      performedBy: map['performedBy'] ?? 'System Admin',
      details: map['details'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      category: map['category'] ?? 'security',
      organizationId: map['organizationId'] ?? '',
    );
  }
}

class AuditLogService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuditLogService(this._authService);

  bool get _useFirebase => _authService.isFirebaseInitialized;

  static final List<AuditLogModel> _mockLogs = [
    AuditLogModel(
      id: 'log_1',
      action: 'Updated Geofence Settings',
      performedBy: 'Admin Owner',
      details: 'Set office location to Lat 23.8103, Lng 90.4125 with 200m radius',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      category: 'settings',
      organizationId: 'mock_org_1',
    ),
    AuditLogModel(
      id: 'log_2',
      action: 'Promoted Staff to HR Manager',
      performedBy: 'Admin Owner',
      details: 'Promoted HR Manager (hr@ems.com) role from Staff to HR Lead',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      category: 'role',
      organizationId: 'mock_org_1',
    ),
    AuditLogModel(
      id: 'log_3',
      action: 'Posted Announcement',
      performedBy: 'Admin Owner',
      details: 'Posted "Annual Performance Review 2026" with High Priority',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      category: 'notice',
      organizationId: 'mock_org_1',
    ),
  ];

  Stream<List<AuditLogModel>> streamLogs(String organizationId) {
    if (_useFirebase) {
      return _firestore
          .collection('audit_logs')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => AuditLogModel.fromMap(doc.data())).toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
    }

    return Stream.periodic(const Duration(seconds: 1), (_) {
      final list = _mockLogs.where((l) => l.organizationId == organizationId).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<void> logAction(
    String action,
    String performedBy,
    String details,
    String category,
    String organizationId,
  ) async {
    final now = DateTime.now();
    final id = _useFirebase
        ? _firestore.collection('audit_logs').doc().id
        : "log_${now.millisecondsSinceEpoch}";

    final logItem = AuditLogModel(
      id: id,
      action: action,
      performedBy: performedBy,
      details: details,
      timestamp: now,
      category: category,
      organizationId: organizationId,
    );

    if (_useFirebase) {
      try {
        await _firestore.collection('audit_logs').doc(id).set(logItem.toMap());
      } catch (e) {
        debugPrint("Firebase Audit Log Error: $e");
      }
    }

    _mockLogs.insert(0, logItem);
  }
}
