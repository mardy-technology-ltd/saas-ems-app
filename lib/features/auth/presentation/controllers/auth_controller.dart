import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  return service;
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final OrganizationModel? organization;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.user,
    this.organization,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    OrganizationModel? organization,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      organization: organization ?? this.organization,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _init();
    return AuthState(isLoading: true);
  }

  Future<void> _init() async {
    final authService = ref.read(authServiceProvider);
    await authService.init();
    state = AuthState(
      user: authService.currentUser,
      organization: authService.currentOrg,
      isLoading: false,
    );
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.signIn(email, password);
      state = AuthState(
        user: user,
        organization: authService.currentOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName, String role) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.signUp(email, password, displayName, role);
      state = AuthState(
        user: user,
        organization: authService.currentOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> createOrganization(String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.createOrganization(name);
      state = AuthState(
        user: authService.currentUser,
        organization: authService.currentOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> joinOrganization(String inviteCode) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      await authService.joinOrganization(inviteCode);
      state = AuthState(
        user: authService.currentUser,
        organization: authService.currentOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> updateOrganizationSettings(double latitude, double longitude, double radius, String checkInTime, String checkOutTime) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      final updatedOrg = await authService.updateOrganizationSettings(latitude, longitude, radius, checkInTime, checkOutTime);
      state = AuthState(
        user: authService.currentUser,
        organization: updatedOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> updateOrganizationLogo(String logoUrl) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final authService = ref.read(authServiceProvider);
    try {
      final updatedOrg = await authService.updateOrganizationLogo(logoUrl);
      state = AuthState(
        user: authService.currentUser,
        organization: updatedOrg,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = AuthState();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
