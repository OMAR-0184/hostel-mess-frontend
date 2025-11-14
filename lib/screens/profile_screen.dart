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
import 'edit_profile_screen.dart';
import 'feedback_screen.dart';
import 'my_bookings_screen.dart'; 


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('PROFILE', 
          style: TextStyle(
            color: theme.colorScheme.primary, 
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2,
          )
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SafeArea(
        top: false,
        child: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(context, theme, user),
                    const SizedBox(height: 24),
                    
                    if (user.role == 'convenor' || user.role == 'mess_committee') ...[
                      _buildSectionTitle(theme, "MANAGEMENT"),
                      _buildAdminSection(context, user),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionTitle(theme, "MEALS"),
                    _buildMealsSection(context),
                    const SizedBox(height: 24),

                    _buildSectionTitle(theme, "PREFERENCES"),
                    _buildPreferencesSection(context, theme, user),
                    
                    const SizedBox(height: 40),
                    _buildLogoutButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  // --- 1. HERO PROFILE HEADER ---
  Widget _buildHeroHeader(BuildContext context, ThemeData theme, User user) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Gradient
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode 
                  ? [Colors.black.withOpacity(0.8), Colors.transparent]
                  : [theme.colorScheme.primary.withOpacity(0.05), Colors.transparent],
            ),
          ),
        ),
        
        Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF007BFF)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withOpacity(0.5), 
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  icon: Icon(Icons.edit_outlined, 
                    color: theme.colorScheme.primary, 
                    size: 20
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    padding: EdgeInsets.zero, 
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getRoleColor(user.role).withOpacity(0.5), width: 1),
              ),
              child: Text(
                (user.role ?? 'Student').toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildStatsRow(theme, user),
          ],
        ),
      ],
    );
  }
  Widget _buildStatsRow(ThemeData theme, User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(theme, "Room", "${user.roomNumber}"),
          Container(height: 30, width: 1, color: theme.dividerColor),
          _buildStatItem(theme, "Status", user.isMessActive == true ? "Active" : "Inactive"),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- SECTION HELPERS ---
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context, User user) {
    return Column(
      children: [
        if (user.role == 'convenor')
          _buildModernListTile(
            context: context, 
            icon: Icons.edit_calendar_rounded,
            color: Colors.deepPurple,
            title: "Set Daily Menu",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetMenuScreen())),
          ),
        _buildModernListTile(
          context: context, 
          icon: Icons.campaign_rounded,
          color: Colors.deepPurple,
          title: "Post a Notice",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostNoticeScreen())),
        ),
        if (user.role == 'mess_committee')
          _buildModernListTile(
            context: context, 
            icon: Icons.people_alt_rounded,
            color: Colors.indigo,
            title: "Manage Users",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
          ),
      ],
    );
  }

  Widget _buildMealsSection(BuildContext context) {
    return Column(
      children: [
        _buildModernListTile(
          context: context, 
          icon: Icons.receipt_long_rounded,
          color: Colors.orange,
          title: "Daily Meal List",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealListScreen())),
        ),
        _buildModernListTile(
          context: context, 
          icon: Icons.history_rounded, 
          color: Colors.cyan, 
          title: "My Booking History",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyBookingsScreen())),
        ),
        _buildModernListTile(
          context: context, 
          icon: Icons.star_outline_rounded,
          color: Colors.teal,
          title: "Rate Your Meal", 
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackScreen())), 
),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context, ThemeData theme, User user) {
    return Column(
      children: [
        _buildModernListTile(
          context: context, 
          icon: Icons.lock_outline_rounded,
          color: Colors.blueGrey,
          title: "Reset Password",
          onTap: () => _showResetPasswordConfirmation(context, user),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dark_mode_outlined, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              const Text(
                "Dark Mode",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _buildThemeToggleSwitch(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernListTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => _showLogoutConfirmationDialog(context),
        child: const Text(
          "Log Out",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }


  Widget _buildThemeToggleSwitch(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Switch.adaptive(
      value: isDarkMode,
      activeColor: Colors.blue,
      onChanged: (value) => themeProvider.toggleTheme(),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'convenor': return Colors.amber.shade800;
      case 'mess_committee': return Colors.red.shade600;
      default: return Colors.blue.shade600;
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showResetPasswordConfirmation(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text('Send a password reset token to your email?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(dialogContext)),
            TextButton(
              child: const Text('Send', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final success = await Provider.of<AuthProvider>(context, listen: false).forgotPassword(user.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Email sent!' : 'Failed to send email.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  if(success) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(dialogContext)),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(dialogContext);
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        );
      },
    );
  }
}