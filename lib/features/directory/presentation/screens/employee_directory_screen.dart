import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/auth_service.dart';
import '../controllers/directory_controller.dart';

class EmployeeDirectoryScreen extends ConsumerStatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  ConsumerState<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends ConsumerState<EmployeeDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, admin, hr, employee

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditBottomSheet(UserModel targetUser) {
    // Current logged in user cannot edit their own role/designation here
    final currentUser = ref.read(authNotifierProvider).user;
    final isSelf = currentUser?.uid == targetUser.uid;

    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot edit your own profile in the directory.")),
      );
      return;
    }

    final designationController = TextEditingController(text: targetUser.designation);
    String selectedRole = targetUser.role;
    bool isSaving = false;

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
                    'Edit Employee Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    targetUser.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    targetUser.email,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: designationController,
                    decoration: const InputDecoration(
                      labelText: 'Designation / Title',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'System Access Role',
                      prefixIcon: Icon(Icons.security_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'employee',
                        child: Text('Employee', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'hr',
                        child: Text('HR Manager', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedRole = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  if (isSaving)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () async {
                        setModalState(() {
                          isSaving = true;
                        });
                        
                        try {
                          await ref.read(directoryServiceProvider).updateUser(
                                targetUser.uid,
                                selectedRole,
                                designationController.text,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Employee details updated successfully.'),
                                backgroundColor: AppTheme.secondaryColor,
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
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
    final directoryAsync = ref.watch(directoryStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Employee Directory'),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Admin", "HR", "Employee"].map((role) {
                      final isSelected = _selectedFilter == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(role),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedFilter = role;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: directoryAsync.when(
              data: (users) {
                // Apply Search filter
                var filteredList = users.where((user) {
                  final name = user.displayName.toLowerCase();
                  final email = user.email.toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                // Apply Role filter
                if (_selectedFilter != "All") {
                  filteredList = filteredList
                      .where((user) => user.role.toLowerCase() == _selectedFilter.toLowerCase())
                      .toList();
                }

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No employees found.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final targetUser = filteredList[index];
                    
                    // Style attributes per role
                    Color roleColor = Colors.grey;
                    if (targetUser.role == 'admin') roleColor = AppTheme.primaryColor;
                    if (targetUser.role == 'hr') roleColor = AppTheme.secondaryColor;

                    final initials = targetUser.displayName.isNotEmpty
                        ? targetUser.displayName.trim().substring(0, 1).toUpperCase()
                        : "?";

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.1),
                          child: Text(
                            initials,
                            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          targetUser.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(targetUser.designation),
                            Text(targetUser.email, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            targetUser.role.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => _showEditBottomSheet(targetUser),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(
                child: Text('Error loading directory: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
