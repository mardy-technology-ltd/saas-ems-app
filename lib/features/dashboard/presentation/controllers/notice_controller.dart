import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notice_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final noticeServiceProvider = Provider<NoticeService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return NoticeService(authService);
});

final noticeStreamProvider = StreamProvider<List<NoticeModel>>((ref) {
  final org = ref.watch(authNotifierProvider).organization;
  if (org == null || org.organizationId.isEmpty) {
    return Stream.value([]);
  }
  final noticeService = ref.watch(noticeServiceProvider);
  return noticeService.streamNotices(org.organizationId);
});
