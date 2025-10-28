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
  final TextEditingController _roomFilterController = TextEditingController();
  String _selectedRole = 'All';
  List<User> _filteredUsers = [];
  
  final List<String> _roles = ['All', 'student', 'convenor', 'mess_committee'];

  @override
  void initState() {
    super.initState();
    // Add listeners to all filter inputs
    _searchController.addListener(_filterUsers);
    _roomFilterController.addListener(_filterUsers);
    
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
    _roomFilterController.removeListener(_filterUsers);
    _roomFilterController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final nameQuery = _searchController.text.toLowerCase();
    final roomQuery = _roomFilterController.text;
    
    setState(() {
      _filteredUsers = adminProvider.users.where((user) {
        // 1. Name search (from search bar)
        final nameMatches = user.name.toLowerCase().contains(nameQuery);

        // 2. Room filter (from filter sheet)
        final roomMatches = roomQuery.isEmpty
            ? true
            : user.roomNumber.toString().contains(roomQuery);

        // 3. Role filter (from filter sheet)
        final roleMatches = _selectedRole == 'All'
            ? true
            : user.role == _selectedRole;

        return nameMatches && roomMatches && roleMatches;
      }).toList();
    });
  }

  Future<void> _refreshUsers() async {
    await Provider.of<AdminProvider>(context, listen: false).fetchAllUsers(forceRefresh: true);
    _filterUsers(); // Re-apply filters after refresh
  }

  void _clearFilters() {
    _searchController.clear();
    _roomFilterController.clear();
    setState(() {
      _selectedRole = 'All';
    });
    _filterUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();
    
    final bool filtersActive = _selectedRole != 'All' || _roomFilterController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              filtersActive ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: filtersActive ? theme.colorScheme.primary : Colors.grey,
            ),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter Users',
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 0.0, 16.0, 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${_filteredUsers.length} of ${adminProvider.users.length} users",
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[700]),
                ),
                if (filtersActive || _searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildActiveFilterChips(theme),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                if (adminProvider.isLoading && adminProvider.users.isEmpty) {
                  return Center(child: Lottie.asset('assets/loader.json', height: 100));
                }
                if (adminProvider.users.isEmpty) {
                  return _buildEmptyState();
                }
                if (_filteredUsers.isEmpty) {
                  return _buildInfoMessage(
                    icon: Icons.search_off,
                    message: 'No users found matching your criteria.',
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
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name...',
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

  Widget _buildActiveFilterChips(ThemeData theme) {
    if (_selectedRole == 'All' && _roomFilterController.text.isEmpty) {
      return const SizedBox.shrink(); // No filters, show nothing
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          if (_selectedRole != 'All')
            Chip(
              label: Text('Role: $_selectedRole'),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              onDeleted: () {
                setState(() => _selectedRole = 'All');
                _filterUsers();
              },
            ),
          if (_roomFilterController.text.isNotEmpty)
            Chip(
              label: Text('Room: ${_roomFilterController.text}'),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              onDeleted: () {
                _roomFilterController.clear();
                _filterUsers();
              },
            ),
        ],
      ),
    );
  }
  
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Use StatefulBuilder to manage the sheet's internal state
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Users', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  // Filter by Role
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.security_outlined),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.replaceAll('_', ' ').toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() {
                          _selectedRole = value;
                        });
                        setState(() {}); // Update main screen state
                        _filterUsers(); // Re-run filter
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Filter by Room Number
                  TextField(
                    controller: _roomFilterController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Room Number',
                      hintText: 'Enter room no...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.room_outlined),
                    ),
                    onChanged: (value) {
                      _filterUsers(); // Filter as user types
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                  ..._roles.where((role) => role != 'All').map((role) { // Use the same role list, skip 'All'
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