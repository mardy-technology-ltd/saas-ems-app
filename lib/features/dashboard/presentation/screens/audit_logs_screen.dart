import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../controllers/audit_log_controller.dart';
import '../../../../core/services/audit_log_service.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  final bool hideAppBar;
  const AuditLogsScreen({super.key, this.hideAppBar = false});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: const Text('Security & Activity Audit Logs'),
            ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Settings", "Role", "Notice", "Security"].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Audit Logs Timeline List
          Expanded(
            child: auditLogsAsync.when(
              data: (logs) {
                var filtered = logs;
                if (_selectedCategory != "All") {
                  filtered = logs
                      .where((l) => l.category.toLowerCase() == _selectedCategory.toLowerCase())
                      .toList();
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No security audit logs found.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final log = filtered[index];
                    return _buildLogTile(log);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading audit logs: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(AuditLogModel log) {
    Color iconColor = AppTheme.primaryColor;
    IconData icon = Icons.security_rounded;

    if (log.category == 'settings') {
      iconColor = Colors.blue;
      icon = Icons.tune_rounded;
    } else if (log.category == 'role') {
      iconColor = Colors.purple;
      icon = Icons.manage_accounts_rounded;
    } else if (log.category == 'notice') {
      iconColor = Colors.orange;
      icon = Icons.campaign_rounded;
    }

    final formattedDate = "${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} ${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}";

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: iconColor.withOpacity(0.15),
                        child: Icon(icon, size: 18, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          log.action,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.category.toUpperCase(),
                    style: TextStyle(color: iconColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              log.details,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      log.performedBy,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
