// lib/screens/user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/user.dart';
import '../provider/admin_provider.dart';
import 'package:lottie/lottie.dart';
import '../provider/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.fetchAllUsers().then((_) {
        if (mounted) {
           setState(() {
            _filteredUsers = adminProvider.users;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = adminProvider.users;
      } else {
        _filteredUsers = adminProvider.users.where((user) {
          final nameMatches = user.name.toLowerCase().contains(query);
          final emailMatches = user.email.toLowerCase().contains(query);
          final roomMatches = user.roomNumber.toString().contains(query);
          return nameMatches || emailMatches || roomMatches;
        }).toList();
      }
    });
  }

  Future<void> _refreshUsers() async {
    await Provider.of<AdminProvider>(context, listen: false).fetchAllUsers(forceRefresh: true);
    _filterUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading && adminProvider.users.isEmpty) {
                  return Center(child: Lottie.asset('assets/loader.json', height: 100));
                }
                if (adminProvider.users.isEmpty) {
                  return _buildEmptyState();
                }
                if (_filteredUsers.isEmpty && _searchController.text.isNotEmpty) {
                  return _buildInfoMessage(
                    icon: Icons.search_off,
                    message: 'No users found for "${_searchController.text}".',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refreshUsers,
                  child: AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final user = _filteredUsers[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildUserCard(context, user, theme),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, email, or room...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardTheme.color,
        ),
      ),
    );
  }
  
  Widget _buildUserCard(BuildContext context, User user, ThemeData theme) {
    final userRole = user.role ?? 'student';
    final roleColor = _getRoleColor(userRole);

    return Card(
      color: theme.cardTheme.color,
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: theme.cardTheme.elevation,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 18, color: roleColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(user.email, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(theme, Icons.room_outlined, 'Room: ${user.roomNumber}'),
                _buildRoleChip(userRole, roleColor),
              ],
            ),
             const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mess Status", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: user.isMessActive ?? false,
                    onChanged: (bool value) async {
                      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final success = await adminProvider.updateUserMessStatus(user.id, value);
                      if (mounted) {
                        if (success) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mess status updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                           );
                           if (user.id == authProvider.user?.id) {
                              await authProvider.fetchCurrentUser();
                           }
                           _refreshUsers(); // Refresh the user list
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(adminProvider.error ?? 'Failed to update status.'),
                               backgroundColor: Colors.red,
                             ),
                           );
                        }
                      }
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildActionButtons(context, user, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String role, Color color) {
    return Chip(
      label: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildActionButtons(BuildContext context, User user, ThemeData theme) {
    final adminProvider = context.watch<AdminProvider>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Change Role'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: theme.dividerColor),
            ),
            onPressed: (adminProvider.isSubmitting ?? false) ? null : () => _showChangeRoleBottomSheet(context, user),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              foregroundColor: Colors.red.shade400,
              side: BorderSide(color: Colors.red.shade400.withOpacity(0.5)),
            ),
            onPressed: (adminProvider.isSubmitting ?? false) ? null : () => _showDeleteUserDialog(context, user),
          ),
        ),
      ],
    );
  }

  void _showChangeRoleBottomSheet(BuildContext context, User user) {
    String selectedRole = user.role ?? 'student';
    final roles = ['student', 'convenor', 'mess_committee'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change Role for ${user.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ...roles.map((role) {
                    return RadioListTile<String>(
                      title: Text(role.replaceAll('_', ' ').toUpperCase()),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedRole = value);
                        }
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Save Changes'),
                      onPressed: () async {
                        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                        Navigator.of(bottomSheetContext).pop();
                        final success = await adminProvider.updateUserRole(user.id, selectedRole);
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'User role updated successfully!' : adminProvider.error ?? 'Failed to update user role.'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text('Are you sure you want to delete the user "${user.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                Navigator.of(dialogContext).pop();
                final success = await adminProvider.deleteUser(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User deleted successfully!' : adminProvider.error ?? 'Failed to delete user.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'convenor':
        return Colors.orange.shade700;
      case 'mess_committee':
        return Colors.pink.shade600;
      case 'student':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty_list.json',
            width: 250,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Users Found',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no users to manage at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoMessage({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}