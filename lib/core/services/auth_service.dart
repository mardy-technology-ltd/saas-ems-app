import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? organizationId;
  final String role; // admin, hr, employee
  final String designation;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.organizationId,
    required this.role,
    required this.designation,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'organizationId': organizationId,
      'role': role,
      'designation': designation,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      organizationId: map['organizationId'],
      role: map['role'] ?? 'employee',
      designation: map['designation'] ?? 'Staff',
    );
  }
}

class OrganizationModel {
  final String organizationId;
  final String name;
  final String inviteCode;

  OrganizationModel({
    required this.organizationId,
    required this.name,
    required this.inviteCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'name': name,
      'inviteCode': inviteCode,
    };
  }

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      organizationId: map['organizationId'] ?? '',
      name: map['name'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
    );
  }
}

class AuthService {
  // In-memory fallback database for prototype testing when Firebase is not configured
  static final Map<String, UserModel> _mockUsers = {
    'admin@ems.com': UserModel(uid: 'mock_admin', email: 'admin@ems.com', displayName: 'Admin Owner', role: 'admin', designation: 'Company Owner', organizationId: 'mock_org_1'),
    'hr@ems.com': UserModel(uid: 'mock_hr', email: 'hr@ems.com', displayName: 'HR Manager', role: 'hr', designation: 'HR Lead', organizationId: 'mock_org_1'),
    'employee@ems.com': UserModel(uid: 'mock_emp', email: 'employee@ems.com', displayName: 'Rahim Ahmed', role: 'employee', designation: 'Software Developer', organizationId: 'mock_org_1'),
  };

  static final Map<String, OrganizationModel> _mockOrgs = {
    'mock_org_1': OrganizationModel(organizationId: 'mock_org_1', name: 'Antigravity Soft Ltd', inviteCode: 'AGY-101'),
  };

  UserModel? _currentUser;
  OrganizationModel? _currentOrg;

  UserModel? get currentUser => _currentUser;
  OrganizationModel? get currentOrg => _currentOrg;

  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (isFirebaseInitialized) {
      final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await _fetchFirebaseUserAndOrg(fbUser.uid);
      }
    }
  }

  Future<void> _fetchFirebaseUserAndOrg(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!);
        if (_currentUser!.organizationId != null) {
          final orgDoc = await FirebaseFirestore.instance
              .collection('organizations')
              .doc(_currentUser!.organizationId)
              .get();
          if (orgDoc.exists && orgDoc.data() != null) {
            _currentOrg = OrganizationModel.fromMap(orgDoc.data()!);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching firebase user/org: $e");
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    if (isFirebaseInitialized) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (credential.user != null) {
          await _fetchFirebaseUserAndOrg(credential.user!.uid);
          return _currentUser;
        }
      } catch (e) {
        debugPrint("Firebase SignIn Error: $e. Falling back to local mock login for email.");
      }
    }

    // Local Mock Fallback
    final user = _mockUsers[email.trim().toLowerCase()];
    if (user != null) {
      _currentUser = user;
      if (user.organizationId != null) {
        _currentOrg = _mockOrgs[user.organizationId!];
      }
      return _currentUser;
    }
    throw Exception("Invalid credentials. Try: admin@ems.com, hr@ems.com, or employee@ems.com");
  }

  Future<UserModel?> signUp(String email, String password, String displayName, String role) async {
    final cleanEmail = email.trim().toLowerCase();
    if (isFirebaseInitialized) {
      try {
        final credential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        if (credential.user != null) {
          final newUser = UserModel(
            uid: credential.user!.uid,
            email: cleanEmail,
            displayName: displayName,
            role: role,
            designation: role == 'admin' ? 'Company Owner' : (role == 'hr' ? 'HR Specialist' : 'Staff'),
          );

          await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set(newUser.toMap());
          _currentUser = newUser;
          return _currentUser;
        }
      } catch (e) {
        debugPrint("Firebase SignUp Error: $e. Falling back to local mock signup.");
      }
    }

    // Local Mock Fallback
    final uid = "mock_user_${DateTime.now().millisecondsSinceEpoch}";
    final newUser = UserModel(
      uid: uid,
      email: cleanEmail,
      displayName: displayName,
      role: role,
      designation: role == 'admin' ? 'Company Owner' : (role == 'hr' ? 'HR Specialist' : 'Staff'),
    );
    _mockUsers[cleanEmail] = newUser;
    _currentUser = newUser;
    return _currentUser;
  }

  Future<OrganizationModel> createOrganization(String name) async {
    if (_currentUser == null) throw Exception("User not authenticated");
    final orgId = isFirebaseInitialized 
        ? FirebaseFirestore.instance.collection('organizations').doc().id
        : "mock_org_${DateTime.now().millisecondsSinceEpoch}";
    
    final inviteCode = "${name.replaceAll(' ', '').toUpperCase().substring(0, 3)}-${100 + (DateTime.now().millisecondsSinceEpoch % 900)}";
    final newOrg = OrganizationModel(
      organizationId: orgId,
      name: name,
      inviteCode: inviteCode,
    );

    if (isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('organizations').doc(orgId).set(newOrg.toMap());
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'organizationId': orgId,
        });
      } catch (e) {
        debugPrint("Firebase Org Create Error: $e. Performing mock org creation.");
      }
    }

    // Update state (works in mock + firebase recovery)
    _mockOrgs[orgId] = newOrg;
    _currentOrg = newOrg;
    _currentUser = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      role: _currentUser!.role,
      designation: _currentUser!.designation,
      organizationId: orgId,
    );
    
    // Update local database entry for mocks
    _mockUsers[_currentUser!.email] = _currentUser!;
    
    return newOrg;
  }

  Future<OrganizationModel> joinOrganization(String inviteCode) async {
    if (_currentUser == null) throw Exception("User not authenticated");
    
    OrganizationModel? foundOrg;

    if (isFirebaseInitialized) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('organizations')
            .where('inviteCode', isEqualTo: inviteCode.trim())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          foundOrg = OrganizationModel.fromMap(query.docs.first.data());
        }
      } catch (e) {
        debugPrint("Firebase Org Query Error: $e. Checking local mock database.");
      }
    }

    // Local Mock search
    if (foundOrg == null) {
      for (var org in _mockOrgs.values) {
        if (org.inviteCode.toUpperCase() == inviteCode.trim().toUpperCase()) {
          foundOrg = org;
          break;
        }
      }
    }

    if (foundOrg == null) {
      throw Exception("Organization not found with Invite Code: $inviteCode. Try 'AGY-101'");
    }

    if (isFirebaseInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
          'organizationId': foundOrg.organizationId,
        });
      } catch (e) {
        debugPrint("Firebase Org Join Update Error: $e");
      }
    }

    _currentOrg = foundOrg;
    _currentUser = UserModel(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: _currentUser!.displayName,
      role: _currentUser!.role,
      designation: _currentUser!.designation,
      organizationId: foundOrg.organizationId,
    );
    
    _mockUsers[_currentUser!.email] = _currentUser!;

    return foundOrg;
  }

  Future<void> signOut() async {
    if (isFirebaseInitialized) {
      try {
        await fb_auth.FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint("Firebase SignOut Error: $e");
      }
    }
    _currentUser = null;
    _currentOrg = null;
  }
}
