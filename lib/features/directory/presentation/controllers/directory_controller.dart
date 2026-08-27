import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/directory_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final directoryServiceProvider = Provider<DirectoryService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return DirectoryService(authService);
});

// A stream of organization members
final directoryStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final directoryService = ref.watch(directoryServiceProvider);
  final authState = ref.watch(authNotifierProvider);
  final orgId = authState.organization?.organizationId;
  
  if (orgId == null) {
    return Stream.value(<UserModel>[]);
  }
  
  return directoryService.getOrganizationUsers(orgId);
});
