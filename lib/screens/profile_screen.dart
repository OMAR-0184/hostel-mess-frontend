// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/auth_provider.dart';
import 'user_management_screen.dart';
import 'meallist_screen.dart';
import 'admin/set_menu_screen.dart';
import 'admin/post_notice_screen.dart';

class ProfileScreen extends StatelessWidget {
  // Add a const constructor for StatelessWidget
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            if (user != null) ...[
              _buildUserInfoSection(theme, user),
              const SizedBox(height: 24),
              if (user.role == 'convenor' || user.role == 'mess_committee')
                _buildAdminPanel(theme, context, user),
            ],
            const SizedBox(height: 24),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  /// A modernized user information header.
  Widget _buildUserInfoSection(ThemeData theme, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style:
                theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildRoleChip(theme, user.role ?? 'student'),
          const Divider(height: 32),
          _buildInfoRow(theme, Icons.email_outlined, user.email),
          const SizedBox(height: 12),
          _buildInfoRow(theme, Icons.room_outlined, 'Room No: ${user.roomNumber}'),
        ],
      ),
    );
  }

  /// A styled chip to display the user's role.
  Widget _buildRoleChip(ThemeData theme, String role) {
    Color chipColor;
    switch (role) {
      case 'convenor':
        chipColor = Colors.amber.shade700;
        break;
      case 'mess_committee':
        chipColor = Colors.red.shade600;
        break;
      default:
        chipColor = Colors.green.shade600;
    }
    return Chip(
      label: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
    );
  }

  /// A helper to create consistent rows for user details.
  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
      ],
    );
  }

  /// A modernized admin panel section.
  Widget _buildAdminPanel(ThemeData theme, BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Admin Panel",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          if (user.role == 'convenor') ...[
            _buildAdminButton(
              context,
              icon: Icons.edit_calendar_outlined,
              text: 'Set Daily Menu',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SetMenuScreen())),
            ),
            _buildAdminButton(
              context,
              icon: Icons.list_alt_outlined,
              text: 'View Daily Meal List',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MealListScreen())),
            ),
          ],
          if (user.role == 'mess_committee') ...[
            _buildAdminButton(
              context,
              icon: Icons.people_outline,
              text: 'Manage User Roles',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => UserManagementScreen())),
            ),
            _buildAdminButton(
              context,
              icon: Icons.list_alt_outlined,
              text: 'View Daily Meal List',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MealListScreen())),
            ),
            _buildAdminButton(
              context,
              icon: Icons.post_add_outlined,
              text: 'Post a New Notice',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PostNoticeScreen())),
            ),
          ]
        ],
      ),
    );
  }

  /// A styled button for admin actions.
  Widget _buildAdminButton(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  /// A styled logout button.
  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      onPressed: () {
        Provider.of<AuthProvider>(context, listen: false).logout();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}