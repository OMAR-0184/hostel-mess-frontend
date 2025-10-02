import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/user.dart';
import '../provider/admin_provider.dart';

class UserManagementScreen extends StatefulWidget {
  UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the list of users when the screen is first loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (adminProvider.users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return RefreshIndicator(
            onRefresh: () => adminProvider.fetchAllUsers(),
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: adminProvider.users.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = adminProvider.users[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildUserCard(user),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final userRole = user.role ?? 'student';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(userRole).withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            style: TextStyle(color: _getRoleColor(userRole), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Room: ${user.roomNumber} | ${user.email}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleChip(userRole),
            _buildUserActionsMenu(user),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Chip(
      label: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: _getRoleColor(role),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }

  Widget _buildUserActionsMenu(User user) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'change_role') {
          _showChangeRoleDialog(user);
        } else if (value == 'delete') {
          _showDeleteUserDialog(user);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'change_role',
          child: Text('Change role'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete user'),
        ),
      ],
    );
  }

  void _showChangeRoleDialog(User user) {
    String selectedRole = user.role ?? 'student';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Role for ${user.name}'),
          content: DropdownButton<String>(
            value: selectedRole,
            items: <String>['student', 'convenor', 'mess_committee']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedRole = newValue;
                });
              }
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                adminProvider.updateUserRole(user.id, selectedRole).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User role updated successfully!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(adminProvider.error ?? 'Failed to update user role.'), backgroundColor: Colors.red),
                    );
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete User ${user.name}?'),
          content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                adminProvider.deleteUser(user.id).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User deleted successfully!'), backgroundColor: Colors.green),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(adminProvider.error ?? 'Failed to delete user.'), backgroundColor: Colors.red),
                    );
                  }
                });
                Navigator.of(context).pop();
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
        return Colors.amber.shade700;
      case 'mess_committee':
        return Colors.red.shade600;
      case 'student':
      default:
        return Colors.green.shade600;
    }
  }
}