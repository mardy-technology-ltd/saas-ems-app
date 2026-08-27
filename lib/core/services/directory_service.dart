import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class DirectoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  DirectoryService(this._authService);

  bool get _useFirebase => _authService.isFirebaseInitialized;

  // Streams users belonging to the same organization
  Stream<List<UserModel>> getOrganizationUsers(String organizationId) {
    if (_useFirebase) {
      return _firestore
          .collection('users')
          .where('organizationId', isEqualTo: organizationId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      });
    }

    // Fallback: Mock stream based on in-memory mock data
    // Simply fetch mock users matching organization ID
    return Stream.periodic(const Duration(seconds: 1), (_) {
      // Accessing package-internal data of AuthService using mock mapping
      // Since _mockUsers is static in AuthService, we can simulate:
      return [
        UserModel(uid: 'mock_admin', email: 'admin@ems.com', displayName: 'Admin Owner', role: 'admin', designation: 'Company Owner', organizationId: organizationId),
        UserModel(uid: 'mock_hr', email: 'hr@ems.com', displayName: 'HR Manager', role: 'hr', designation: 'HR Lead', organizationId: organizationId),
        UserModel(uid: 'mock_emp', email: 'employee@ems.com', displayName: 'Rahim Ahmed', role: 'employee', designation: 'Software Developer', organizationId: organizationId),
      ];
    });
  }

  // Updates an employee's role and designation
  Future<void> updateUser(String uid, String role, String designation) async {
    if (_useFirebase) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'role': role,
          'designation': designation,
        });
        return;
      } catch (e) {
        debugPrint("Firebase Directory Update Error: $e. Falling back to local update.");
      }
    }

    // Mock implementation
    debugPrint("Mock updated user $uid to Role: $role, Designation: $designation");
  }
}
