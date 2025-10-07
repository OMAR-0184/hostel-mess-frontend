// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  // NEW: State to control the success animation
  bool _showSuccessAnimation = false;

  void _sendResetLink() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.forgotPassword(
      _emailController.text.trim(),
    );

    if (success) {
      if (mounted) {
        // Show the success animation instead of just a snackbar
        setState(() {
          _isLoading = false;
          _showSuccessAnimation = true;
        });
        
        // After a delay, navigate to the reset screen
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
             );
          }
        });
      }
    } else {
      if (mounted) {
        final errorMessage = authProvider.errorMessage ?? 'Failed to send reset link.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            // NEW: Use AnimatedCrossFade to switch between the form and success animation
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: _showSuccessAnimation ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _buildForm(), // The original form
              secondChild: _buildSuccessView(), // The new success animation view
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Extracted the form into its own method for clarity
  Widget _buildForm() {
    final theme = Theme.of(context);
    return AnimationLimiter(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 500),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            Lottie.asset(
              'assets/forgot_password.json', // Animation for the form
              height: 220,
            ),
            const SizedBox(height: 24),
            Text(
              'Forgot Password?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter your email address below to receive a password reset token.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildTextField(_emailController, 'Email', Icons.email_outlined, isEmail: true),
            const SizedBox(height: 24),
            _isLoading
                ? Center(child: Lottie.asset('assets/loader.json', height: 60))
                : _buildSendLinkButton(),
          ],
        ),
      ),
    );
  }

  // NEW: The success view with its own animation
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lottie.asset(
          'assets/email_sent.json', // A new animation for the success state
          height: 220,
          repeat: false,
        ),
        const SizedBox(height: 24),
        const Text(
          'Email Sent!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 16),
        const Text(
          'A password reset token has been sent to your email. Please check your inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon, {bool isEmail = false}) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: theme.cardTheme.color,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildSendLinkButton() {
    return ElevatedButton(
      onPressed: _sendResetLink,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        elevation: 0,
      ),
      child: const Text('Send Reset Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}