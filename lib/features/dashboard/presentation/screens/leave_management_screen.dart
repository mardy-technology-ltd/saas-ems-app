import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/leave_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/leave_controller.dart';

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen> {
  String _selectedFilter = 'All';

  void _showApplyLeaveModal(BuildContext context) {
    final reasonController = TextEditingController();
    String leaveType = 'Casual Leave';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    DateTime endDate = DateTime.now().add(const Duration(days: 2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Apply for Leave',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Leave Type Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: leaveType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Leave Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave (CL)')),
                      DropdownMenuItem(value: 'Medical Leave', child: Text('Medical Leave (ML)')),
                      DropdownMenuItem(value: 'Earned Leave', child: Text('Earned Leave (EL)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => leaveType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Selection Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: Text('From: ${startDate.day}/${startDate.month}/${startDate.year}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setModalState(() => endDate = picked);
                            }
                          },
                          icon: const Icon(Icons.event_available_rounded, size: 18),
                          label: Text('To: ${endDate.day}/${endDate.month}/${endDate.year}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reason Input
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Leave',
                      hintText: 'State your reason for taking leave...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please state a reason for your leave application.')),
                        );
                        return;
                      }

                      final authState = ref.read(authNotifierProvider);
                      final user = authState.user;
                      final org = authState.organization;

                      if (user == null || org == null) return;

                      await ref.read(leaveServiceProvider).submitLeaveRequest(
                            userId: user.uid,
                            userName: user.displayName,
                            userRole: user.role,
                            leaveType: leaveType,
                            startDate: startDate,
                            endDate: endDate,
                            reason: reasonController.text.trim(),
                            organizationId: org.organizationId,
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Leave application submitted successfully!'),
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      }
                    },
                    child: const Text('Submit Application'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAdminOrHR = user?.role == 'admin' || user?.role == 'hr';
    final leavesAsync = ref.watch(leaveStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      body: leavesAsync.when(
        data: (leaves) {
          final pendingCount = leaves.where((l) => l.status == 'PENDING').length;
          final approvedCount = leaves.where((l) => l.status == 'APPROVED').length;

          List<LeaveRequestModel> filteredLeaves = leaves;
          if (_selectedFilter != 'All') {
            filteredLeaves = leaves.where((l) => l.status == _selectedFilter.toUpperCase()).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Action & Overview Header Card
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdminOrHR ? 'Leave Approvals' : 'My Leave Dashboard',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                Text(
                                  isAdminOrHR ? 'Review & action staff applications' : 'Submit leave requests & track status',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showApplyLeaveModal(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Apply'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatBadge('Total Applications', '${leaves.length}', AppTheme.primaryColor, const Color(0xFFEFF6FF)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatBadge('Pending Review', '$pendingCount', Colors.orange, const Color(0xFFFFF7ED)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatBadge('Approved', '$approvedCount', AppTheme.secondaryColor, const Color(0xFFECFDF5)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Pending', 'Approved', 'Rejected'].map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilter = filter);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Applications List View
                if (filteredLeaves.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No leave applications found.',
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    children: filteredLeaves.map((leave) {
                      Color statusColor = Colors.orange;
                      if (leave.status == 'APPROVED') statusColor = AppTheme.secondaryColor;
                      if (leave.status == 'REJECTED') statusColor = Colors.redAccent;

                      final isPending = leave.status == 'PENDING';

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: Text(
                                          leave.userName.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            leave.userName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            leave.leaveType,
                                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      leave.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range_rounded, size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${leave.startDate.day}/${leave.startDate.month}/${leave.startDate.year} - ${leave.endDate.day}/${leave.endDate.month}/${leave.endDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${leave.totalDays} Day(s)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${leave.reason}',
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                              
                              // Admin / HR Action Buttons for Pending Requests
                              if (isAdminOrHR && isPending) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => ref.read(leaveServiceProvider).updateLeaveStatus(leave.id, 'REJECTED'),
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                      label: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.redAccent),
                                        minimumSize: const Size(0, 34),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => ref.read(leaveServiceProvider).updateLeaveStatus(leave.id, 'APPROVED'),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: const Text('Approve', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.secondaryColor,
                                        minimumSize: const Size(0, 34),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading leaves: $e')),
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
