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
    // FIX: Provide a default value ('student') if the user's role is null.
    // This creates a non-nullable variable that is safe to use below.
    final userRole = user.role ?? 'student';

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          // Use the safe userRole variable.
          backgroundColor: _getRoleColor(userRole).withOpacity(0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0] : '?',
            // Use the safe userRole variable.
            style: TextStyle(color: _getRoleColor(userRole), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Room: ${user.roomNumber} | ${user.email}'),
        // Use the safe userRole variable.
        trailing: _buildRoleChip(userRole),
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