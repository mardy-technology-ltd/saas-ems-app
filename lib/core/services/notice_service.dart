import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String organizationId;
  final DateTime createdAt;
  final String priority; // 'high', 'normal'

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.organizationId,
    required this.createdAt,
    this.priority = 'normal',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorName': authorName,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
    };
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    return NoticeModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      authorName: map['authorName'] ?? 'Admin',
      organizationId: map['organizationId'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      priority: map['priority'] ?? 'normal',
    );
  }
}

class NoticeService {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NoticeService(this._authService);

  bool get _useFirebase => _authService.isFirebaseInitialized;

  static final List<NoticeModel> _mockNotices = [
    NoticeModel(
      id: 'mock_notice_1',
      title: 'Annual Performance Review 2026',
      content: 'All department leads are requested to complete Q3 staff evaluations by Friday.',
      authorName: 'Admin Owner',
      organizationId: 'mock_org_1',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      priority: 'high',
    ),
    NoticeModel(
      id: 'mock_notice_2',
      title: 'System Maintenance Window',
      content: 'Cloud server updates scheduled for midnight this Sunday. Brief 15-min downtime expected.',
      authorName: 'Admin Owner',
      organizationId: 'mock_org_1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      priority: 'normal',
    ),
  ];

  Stream<List<NoticeModel>> streamNotices(String organizationId) {
    if (_useFirebase) {
      return _firestore
          .collection('notices')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => NoticeModel.fromMap(doc.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    }

    return Stream.periodic(const Duration(seconds: 1), (_) {
      final list = _mockNotices.where((n) => n.organizationId == organizationId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<NoticeModel> postNotice(
    String title,
    String content,
    String priority,
    String organizationId,
    String authorName,
  ) async {
    final now = DateTime.now();
    final id = _useFirebase
        ? _firestore.collection('notices').doc().id
        : "mock_notice_${now.millisecondsSinceEpoch}";

    final notice = NoticeModel(
      id: id,
      title: title,
      content: content,
      authorName: authorName,
      organizationId: organizationId,
      createdAt: now,
      priority: priority,
    );

    if (_useFirebase) {
      try {
        await _firestore.collection('notices').doc(id).set(notice.toMap());
      } catch (e) {
        debugPrint("Firebase Post Notice Error: $e");
      }
    }

    _mockNotices.insert(0, notice);
    return notice;
  }

  Future<void> deleteNotice(String id) async {
    if (_useFirebase) {
      try {
        await _firestore.collection('notices').doc(id).delete();
      } catch (e) {
        debugPrint("Firebase Delete Notice Error: $e");
      }
    }

    _mockNotices.removeWhere((n) => n.id == id);
  }
}
