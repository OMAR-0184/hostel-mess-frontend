// lib/screens/notice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../provider/notice_provider.dart';

class NoticeScreen extends StatefulWidget {
  NoticeScreen({Key? key}) : super(key: key);

  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  // --- CORE LOGIC - UNCHANGED ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoticeProvider>(context, listen: false).fetchNotices();
    });
  }
  // --- END OF CORE LOGIC ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          return RefreshIndicator(
            onRefresh: () => noticeProvider.fetchNotices(),
            child: AnimationLimiter(
              child: ListView.builder(
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
                        child: _buildNoticeCard(theme, notice),
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

  /// A modernized card for displaying a single notice.
  Widget _buildNoticeCard(ThemeData theme, Notice notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias, // Ensures the border color respects the rounded corners
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent color border on the left
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
                    Text(
                      notice.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  /// A centered widget to display when the list is empty.
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