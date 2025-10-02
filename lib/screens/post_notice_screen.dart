// lib/screens/admin/post_notice_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/admin_provider.dart';

class PostNoticeScreen extends StatefulWidget {
  // Removed 'const' from the constructor
  PostNoticeScreen({Key? key}) : super(key: key);

  @override
  _PostNoticeScreenState createState() => _PostNoticeScreenState();
}

class _PostNoticeScreenState extends State<PostNoticeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submitNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.postNotice(
      title: _titleController.text,
      content: _contentController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Notice posted successfully!' : adminProvider.error ?? 'Failed to post notice.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Post a New Notice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _titleController,
                labelText: 'Title',
                hintText: 'Enter the notice title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _contentController,
                labelText: 'Content',
                hintText: 'Enter the full content of the notice...',
                icon: Icons.article_outlined,
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the notice content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Consumer<AdminProvider>(
                builder: (context, provider, child) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSubmitting ? null : _submitNotice,
                    icon: const Icon(Icons.send_rounded),
                    label: provider.isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Post Notice'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}