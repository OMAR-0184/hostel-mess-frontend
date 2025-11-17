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
  bool _isFilterExpanded = false;

  final List<String> _roles = ['All', 'student', 'convenor', 'mess_committee'];

  @override
  void initState() {
    super.initState();
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

    // --- Calls setState ---
    setState(() {
      _filteredUsers = adminProvider.users.where((user) {
        final nameMatches = user.name.toLowerCase().contains(nameQuery);
        final roomMatches = roomQuery.isEmpty
            ? true
            : user.roomNumber.toString().contains(roomQuery);
        final roleMatches =
            _selectedRole == 'All' ? true : user.role == _selectedRole;

        return nameMatches && roomMatches && roleMatches;
      }).toList();
    });
  }

  Future<void> _refreshUsers() async {
    // This now just re-applies filters, as the provider consumer handles fetching
    await Provider.of<AdminProvider>(context, listen: false)
        .fetchAllUsers(forceRefresh: true);
    _filterUsers();
  }

  void _clearFilters() {
    _searchController.clear();
    _roomFilterController.clear();
    setState(() {
      _selectedRole = 'All';
    });
    _filterUsers(); // Re-apply filters after clearing
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminProvider = context.watch<AdminProvider>();

    final bool filtersActive =
        _selectedRole != 'All' || _roomFilterController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('MANAGE USERS',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            )),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
              color: filtersActive ? theme.colorScheme.primary : Colors.grey,
            ),
            onPressed: () =>
                setState(() => _isFilterExpanded = !_isFilterExpanded),
            tooltip: 'Filter Users',
          )
        ],
      ),
      // --- MODIFICATION: Added SafeArea wrapper ---
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(theme),
            _buildFilterCard(theme),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Showing ${_filteredUsers.length} users",
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600], fontWeight: FontWeight.bold),
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
            Expanded(
              child: Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  // When provider notifies, we get the new user list
                  // We must re-run the filter to update _filteredUsers
                  // But we can't call setState in build.
                  // We'll call _filterUsers() on success instead.

                  if (adminProvider.isLoading && adminProvider.users.isEmpty) {
                    return Center(
                        child: Lottie.asset('assets/loader.json', height: 100));
                  }
                  if (adminProvider.users.isEmpty) {
                    return _buildEmptyState();
                  }
                  if (_filteredUsers.isEmpty) {
                    return _buildInfoMessage(
                      icon: Icons.search_off,
                      message: 'No users found.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refreshUsers,
                    child: AnimationLimiter(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(height: 1, indent: 70),
                        itemBuilder: (BuildContext context, int index) {
                          final user = _filteredUsers[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 300),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                child:
                                    _buildUserListTile(context, user, theme),
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
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name...',
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            hintStyle: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard(ThemeData theme) {
    IconData _getRoleIcon(String role) {
      switch (role) {
        case 'convenor':
          return Icons.vpn_key_outlined;
        case 'mess_committee':
          return Icons.supervisor_account_outlined;
        default:
          return Icons.shield_outlined;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Visibility(
        visible: _isFilterExpanded,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Filter Options",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.withOpacity(0.3)),
                        color:
                            theme.scaffoldBackgroundColor.withOpacity(0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          style:
                              theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                          icon: Icon(Icons.arrow_drop_down_rounded,
                              color: theme.colorScheme.primary),
                          dropdownColor: theme.cardTheme.color,
                          items: _roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Icon(_getRoleIcon(role),
                                      size: 20,
                                      color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    role.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: role == _selectedRole
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedRole = value);
                              _filterUsers();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _roomFilterController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Room',
                        hintText: 'No.',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Colors.grey.shade500),
                        labelStyle: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.room_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 14),
                      ),
                      style:
                          theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(BuildContext context, User user, ThemeData theme) {
    final userRole = user.role ?? 'student';
    final roleColor = _getRoleColor(userRole);
    final isMessActive = user.isMessActive ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: roleColor.withOpacity(0.1),
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
              fontSize: 18, color: roleColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        user.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Text(
              "Room ${user.roomNumber}",
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: roleColor.withOpacity(0.3), width: 0.5),
              ),
              child: Text(
                userRole.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isMessActive,
              activeColor: Colors.green,
              onChanged: (newValue) {
                // Show confirmation dialog before making any changes
                _showToggleMessStatusDialog(context, user, newValue);
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'role')
                _showChangeRoleBottomSheet(context, user);
              if (value == 'delete')
                _showSecureDeleteUserDialog(context, user);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    const Text('Change Role'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Delete User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangeRoleBottomSheet(BuildContext context, User user) {
    String selectedRole = user.role ?? 'student';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change Role for ${user.name}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ..._roles.where((role) => role != 'All').map((role) {
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00D4FF), // Cyan
                          Color(0xFF007BFF), // Blue
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final adminProvider =
                            Provider.of<AdminProvider>(context, listen: false);
                        Navigator.of(bottomSheetContext).pop();
                        final success = await adminProvider.updateUserRole(
                            user.id, selectedRole);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'User role updated successfully!'
                                  : adminProvider.error ??
                                      'Failed to update user role.'),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success)
                            _filterUsers(); // Re-filter on success
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  void _showSecureDeleteUserDialog(BuildContext context, User user) {
    final TextEditingController deleteConfirmController =
        TextEditingController();
    bool isDeleteEnabled = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete User?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete "${user.name}"? This action cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please type "DELETE" to confirm:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deleteConfirmController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        isDeleteEnabled = (value == 'DELETE');
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  onPressed: isDeleteEnabled
                      ? () async {
                          final adminProvider = Provider.of<AdminProvider>(
                              context,
                              listen: false);
                          Navigator.of(dialogContext).pop();
                          final success =
                              await adminProvider.deleteUser(user.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'User deleted successfully!'
                                    : adminProvider.error ??
                                        'Failed to delete user.'),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                            if (success)
                              _filterUsers(); // Re-filter on success
                          }
                        }
                      : null,
                  child: Text('Delete',
                      style: TextStyle(
                          color:
                              isDeleteEnabled ? Colors.red : Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---
  // --- 1. MODIFIED: _showToggleMessStatusDialog
  // ---
  void _showToggleMessStatusDialog(
      BuildContext context, User user, bool newValue) {
    final String action = newValue ? 'Activate' : 'Deactivate';
    final Color actionColor = newValue ? Colors.green : Colors.orange;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('$action Mess?'),
          content: Text(
            'Are you sure you want to $action mess booking for "${user.name}"?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(action, style: TextStyle(color: actionColor)),
              onPressed: () async {
                final adminProvider =
                    Provider.of<AdminProvider>(context, listen: false);
                Navigator.of(dialogContext).pop();

                final success = await adminProvider.updateUserMessStatus(
                    user.id, newValue);

                if (mounted) {
                  if (success) {
                    // --- THIS IS THE FIX ---
                    // Provider already fetched the new list.
                    // We just need to re-apply local filters
                    // which calls setState() and updates the UI.
                    _filterUsers();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(adminProvider.error ??
                              'Failed to update status.'),
                          backgroundColor: Colors.red),
                    );
                  }
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
        return Colors.blue.shade600;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/empty_list.json', width: 200),
          const SizedBox(height: 20),
          const Text('No Users Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('There are no users to manage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoMessage({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}