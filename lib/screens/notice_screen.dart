// lib/screens/notice_screen.dart

import 'package:flutter/material.dart'; // CORRECTED IMPORT
import 'package:intl/intl.dart'; // CORRECTED IMPORT
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../provider/auth_provider.dart';
import '../provider/notice_provider.dart';

class NoticeScreen extends StatefulWidget {
  NoticeScreen({Key? key}) : super(key: key);

  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoticeProvider>(context, listen: false).fetchNotices();
    });
  }

  Future<void> _refreshNotices() async {
    await Provider.of<NoticeProvider>(context, listen: false).fetchNotices(forceRefresh: true);
  }

  void _showDeleteConfirmationDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notice?'),
          content: Text('Are you sure you want to delete the notice titled "${notice.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await Provider.of<NoticeProvider>(context, listen: false).deleteNotice(notice.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Notice deleted successfully.' : 'Failed to delete notice.'),
                      backgroundColor: success ? Colors.green : Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    final bool isAdmin = user?.role == 'convenor' || user?.role == 'mess_committee';

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<NoticeProvider>(
        builder: (context, noticeProvider, child) {
          if (noticeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (noticeProvider.notices.isEmpty) {
            return _buildInfoMessage(
              icon: Icons.notifications_off_outlined,
              message: 'No notices have been posted yet.',
            );
          }
          return LiquidPullToRefresh(
            onRefresh: _refreshNotices,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.5),
            child: AnimationLimiter(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                itemCount: noticeProvider.notices.length,
                itemBuilder: (BuildContext context, int index) {
                  final notice = noticeProvider.notices[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildNoticeCard(theme, notice, isAdmin),
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

  Widget _buildNoticeCard(ThemeData theme, Notice notice, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 8,
              color: theme.colorScheme.primary,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _showDeleteConfirmationDialog(notice),
                            tooltip: 'Delete Notice',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Posted: ${DateFormat('d MMMM, yyyy').format(notice.createdAt.toLocal())}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Text(
                      notice.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMessage({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}