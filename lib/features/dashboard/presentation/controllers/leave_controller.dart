import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/leave_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final leaveStreamProvider = StreamProvider<List<LeaveRequestModel>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final orgId = authState.organization?.organizationId ?? 'mock_org_1';
  final service = ref.watch(leaveServiceProvider);

  return service.streamLeaves(orgId);
});
