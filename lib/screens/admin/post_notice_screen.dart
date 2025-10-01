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

  void _submitNotice() async {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a New Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter the full content of the notice...',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 32),
            Consumer<AdminProvider>(
              builder: (context, provider, child) => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isSubmitting ? null : _submitNotice,
                  icon: const Icon(Icons.send),
                  label: provider.isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Post Notice'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}