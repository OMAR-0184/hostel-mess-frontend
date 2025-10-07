// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/auth_provider.dart';
import '../provider/theme_provider.dart';
import 'user_management_screen.dart';
import 'meallist_screen.dart';
import 'admin/set_menu_screen.dart';
import 'admin/post_notice_screen.dart';
import 'reset_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          children: [
            if (user != null) ...[
              _buildUserInfoSection(theme, user),
              const SizedBox(height: 24),
              if (user.role == 'convenor' || user.role == 'mess_committee') ...[
                _buildAdminPanel(theme, context, user),
                const SizedBox(height: 24),
              ],
              _buildAccountSettings(context, theme, user),
            ],
            const SizedBox(height: 24),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(ThemeData theme, User user) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // --- UPDATED AVATAR WIDGET ---
          Container(
            width: 90,
            height: 90,
            decoration: isDarkMode
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  )
                : BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.white
                      : theme.colorScheme.primary,
                ),
              ),
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
          _buildInfoRow(
              theme, Icons.room_outlined, 'Room No: ${user.roomNumber}'),
        ],
      ),
    );
  }

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

  Widget _buildAdminPanel(ThemeData theme, BuildContext context, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Admin Panel",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          if (user.role == 'convenor')
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
          _buildAdminButton(
            context,
            icon: Icons.post_add_outlined,
            text: 'Post a New Notice',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => PostNoticeScreen())),
          ),
          if (user.role == 'mess_committee') ...[
            _buildAdminButton(
              context,
              icon: Icons.people_outline,
              text: 'Manage Users',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen())),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildAccountSettings(
      BuildContext context, ThemeData theme, User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Account Settings",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildAdminButton(
            context,
            icon: Icons.lock_reset_outlined,
            text: 'Reset Password',
            onTap: () => _showResetPasswordConfirmation(context, user),
          ),
          const SizedBox(height: 8),
          _buildThemeToggle(context), // The new theme toggle
        ],
      ),
    );
  }

  // NEW WIDGET: The innovative and animated theme toggle switch
  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.color_lens_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Dark Mode',
                style:
                    theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => themeProvider.toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 60,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isDarkMode
                    ? Colors.blueGrey.shade700
                    : Colors.lightBlue.shade100,
              ),
              child: AnimatedAlign(
                alignment:
                    isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 400),
                curve: Curves.fastOutSlowIn,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: child.key == const ValueKey('moon_icon')
                              ? Tween<double>(begin: 0.5, end: 1)
                                  .animate(animation)
                              : Tween<double>(begin: 0.75, end: 1)
                                  .animate(animation),
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: isDarkMode
                          ? Icon(Icons.nightlight_round,
                              color: Colors.blueGrey.shade700,
                              size: 18,
                              key: const ValueKey('moon_icon'))
                          : Icon(Icons.wb_sunny_rounded,
                              color: Colors.orangeAccent,
                              size: 18,
                              key: const ValueKey('sun_icon')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Password Reset'),
          content: const Text(
              'A password reset token will be sent to your registered email. Do you want to continue?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final success = await authProvider.forgotPassword(user.email);

                if (!context.mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset token sent to your email!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ResetPasswordScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.errorMessage ??
                          'Failed to send reset token.'),
                      backgroundColor: Colors.red,
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

  Widget _buildAdminButton(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
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
              Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      onPressed: () {
        _showLogoutConfirmationDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        );
      },
    );
  }
}