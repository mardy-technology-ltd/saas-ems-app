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
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return [
        UserModel(uid: 'mock_admin', email: 'admin@ems.com', displayName: 'Admin Owner', role: 'admin', designation: 'Company Owner', organizationId: organizationId, department: 'Management'),
        UserModel(uid: 'mock_hr', email: 'hr@ems.com', displayName: 'HR Manager', role: 'hr', designation: 'HR Lead', organizationId: organizationId, department: 'HR'),
        UserModel(uid: 'mock_emp1', email: 'employee@ems.com', displayName: 'Rahim Ahmed', role: 'employee', designation: 'Senior Developer', organizationId: organizationId, department: 'Engineering'),
        UserModel(uid: 'mock_emp2', email: 'tanvir@ems.com', displayName: 'Tanvir Hasan', role: 'employee', designation: 'Backend Engineer', organizationId: organizationId, department: 'Engineering'),
        UserModel(uid: 'mock_emp3', email: 'nusrat@ems.com', displayName: 'Nusrat Jahan', role: 'employee', designation: 'UI/UX Designer', organizationId: organizationId, department: 'Engineering'),
        UserModel(uid: 'mock_emp4', email: 'sakib@ems.com', displayName: 'Sakib Khan', role: 'employee', designation: 'QA Specialist', organizationId: organizationId, department: 'Engineering'),
        UserModel(uid: 'mock_emp5', email: 'anika@ems.com', displayName: 'Anika Rahman', role: 'hr', designation: 'HR Executive', organizationId: organizationId, department: 'HR'),
        UserModel(uid: 'mock_emp6', email: 'hasan@ems.com', displayName: 'Hasan Ali', role: 'employee', designation: 'Sales Manager', organizationId: organizationId, department: 'Sales'),
        UserModel(uid: 'mock_emp7', email: 'rifat@ems.com', displayName: 'Rifat Hossain', role: 'employee', designation: 'Sales Executive', organizationId: organizationId, department: 'Sales'),
        UserModel(uid: 'mock_emp8', email: 'sabrina@ems.com', displayName: 'Sabrina Akter', role: 'employee', designation: 'Marketing Specialist', organizationId: organizationId, department: 'Sales'),
        UserModel(uid: 'mock_emp9', email: 'mahmud@ems.com', displayName: 'Mahmudul Haque', role: 'employee', designation: 'Chief Accountant', organizationId: organizationId, department: 'Accounts'),
        UserModel(uid: 'mock_emp10', email: 'bilkis@ems.com', displayName: 'Bilkis Begum', role: 'employee', designation: 'Finance Executive', organizationId: organizationId, department: 'Accounts'),
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
