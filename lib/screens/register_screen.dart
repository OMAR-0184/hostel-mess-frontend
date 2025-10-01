// register_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roomNumberController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    bool success = await Provider.of<AuthProvider>(context, listen: false).register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      int.tryParse(_roomNumberController.text.trim()) ?? 0,
    );
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful! Please check your email to verify.'), backgroundColor: Colors.green),
      );
      if (mounted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Failed! Please try again.'), backgroundColor: Colors.redAccent),
      );
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.asset(
                  'assets/register_animation.json',
                  height: 180,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E232C)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use proper information to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                // UPDATED: Calls to the new text field widget
                _buildTextField(_nameController, 'Full name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'Email address', Icons.email_outlined, isEmail: true),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscureText: true),
                const SizedBox(height: 16),
                _buildTextField(_roomNumberController, 'Room Number', Icons.room_outlined, isNumber: true),
                const SizedBox(height: 24),
                _buildTermsAndConditions(),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildRegisterButton(),
                const SizedBox(height: 32),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Modernized reusable TextField
  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {bool obscureText = false, bool isEmail = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.number : TextInputType.text),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF0D6EFE), width: 2.0),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return const Text('By signing up, you agree to our Terms & Conditions and Privacy Policy', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12));
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _register,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D6EFE),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 0,
      ),
      child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Sign in', style: TextStyle(color: Color(0xFF0D6EFE), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}