import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audit_log_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuditLogService(authService);
});

final auditLogStreamProvider = StreamProvider<List<AuditLogModel>>((ref) {
  final org = ref.watch(authNotifierProvider).organization;
  if (org == null || org.organizationId.isEmpty) {
    return Stream.value([]);
  }
  final service = ref.watch(auditLogServiceProvider);
  return service.streamLogs(org.organizationId);
});
