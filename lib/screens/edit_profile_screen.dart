// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roomNumberController;

  // Track initial state to enable/disable the save button
  late String _initialName;
  late String _initialRoom;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _initialName = user?.name ?? '';
    _initialRoom = user?.roomNumber.toString() ?? '';

    _nameController = TextEditingController(text: _initialName);
    _roomNumberController = TextEditingController(text: _initialRoom);

    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _roomNumberController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != _initialName;
    final roomChanged = _roomNumberController.text.trim() != _initialRoom;
    
    if (mounted) {
      setState(() {
        _hasChanges = nameChanged || roomChanged;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusManager.instance.primaryFocus?.unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      _nameController.text.trim(),
      int.tryParse(_roomNumberController.text.trim()) ?? 0,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to update profile.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // - Consistent App Bar Style
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('EDIT PROFILE', 
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBusinessCardHeader(context),
                const SizedBox(height: 40),
                
                // Name Input
                _buildBigTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Room Input
                _buildBigTextField(
                  controller: _roomNumberController,
                  labelText: 'Room Number',
                  icon: Icons.meeting_room_outlined, // More specific icon
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter room number';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 48),
                
                _buildSmartSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. BUSINESS CARD HEADER ---
  Widget _buildBusinessCardHeader(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final roleColor = _getRoleColor(user?.role);

    return Column(
      children: [
        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              // MODIFIED: Changed to blue gradient
              colors: [Color(0xFF00D4FF), Color(0xFF007BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                // MODIFIED: Changed shadow color
                color: const Color(0xFF00D4FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Text(
              user?.name.isNotEmpty ?? false ? user!.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Role Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor.withOpacity(0.3)),
          ),
          child: Text(
            (user?.role ?? 'Student').toUpperCase(),
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Static Email Text
        Text(
          user?.email ?? '',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- 2. SUPER-SIZED INPUTS ---
  Widget _buildBigTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: 18, // Super-sized font
        fontWeight: FontWeight.w600,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: theme.colorScheme.primary, size: 26),
        ),
        filled: true,
        fillColor: theme.cardTheme.color,
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Extra padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  // --- 4. SMART SAVE BUTTON ---
  Widget _buildSmartSaveButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Button is enabled only if there are changes AND we aren't currently loading
        final bool isEnabled = _hasChanges && !auth.isUpdating;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEnabled 
                ? const LinearGradient(
                    colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade400], // Dimmed state
                  ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF7F00FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [], // No shadow when disabled
          ),
          child: ElevatedButton(
            onPressed: isEnabled ? _submitProfile : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: auth.isUpdating
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                      letterSpacing: 0.5
                    ),
                  ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'convenor': return Colors.amber.shade800;
      case 'mess_committee': return Colors.red.shade600;
      default: return Colors.blue.shade600;
    }
  }
}