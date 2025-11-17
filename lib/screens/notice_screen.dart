// lib/screens/notice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../provider/auth_provider.dart';
import '../provider/notice_provider.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

  @override
  _NoticeScreenState createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoticeProvider>(context, listen: false).fetchNotices();
    });
  }

  Future<void> _refreshNotices() async {
    await Provider.of<NoticeProvider>(context, listen: false)
        .fetchNotices(forceRefresh: true);
  }

  void _showDeleteConfirmationDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Notice?'),
          content: Text(
              'Are you sure you want to delete the notice "${notice.title}"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                final success =
                    await Provider.of<NoticeProvider>(context, listen: false)
                        .deleteNotice(notice.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Notice deleted successfully.'
                          : 'Failed to delete notice.'),
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
    super.build(context);
    
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    final bool isAdmin =
        user?.role == 'convenor' || user?.role == 'mess_committee';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'NOTICES',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        top: false, // AppBar now handles the top area
        bottom: true, 
        child: Container( 
          child: Consumer<NoticeProvider>(
            builder: (context, noticeProvider, child) {
              if (noticeProvider.isLoading && noticeProvider.notices.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (noticeProvider.notices.isEmpty) {
                return _buildInfoMessage(
                  theme,
                  icon: Icons.notifications_none_rounded,
                  message: 'No notices posted yet.',
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshNotices,
                color: theme.colorScheme.primary,
                child: AnimationLimiter(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
                    itemCount: noticeProvider.notices.length, 
                    itemBuilder: (BuildContext context, int index) {
                      final notice = noticeProvider.notices[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: NoticeCard(
                              notice: notice,
                              isAdmin: isAdmin,
                              onDelete: () => _showDeleteConfirmationDialog(notice),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoMessage(ThemeData theme, {required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class NoticeCard extends StatefulWidget {
  final Notice notice;
  final bool isAdmin;
  final VoidCallback onDelete;

  const NoticeCard({
    Key? key,
    required this.notice,
    required this.isAdmin,
    required this.onDelete,
  }) : super(key: key);

  @override
  _NoticeCardState createState() => _NoticeCardState();
}

// ======================================================================
//
//               !!! THIS IS THE LINE WITH THE FIX !!!
//
// Ensure your file has `extends State<NoticeCard>` exactly as written below.
//
// ======================================================================
class _NoticeCardState extends State<NoticeCard> {
  bool _isExpanded = false;

  bool get isLongNotice {
    // Increased the character limit to be less sensitive.
    // A notice is only "long" if it has > 3 newlines OR is > 250 chars.
    const maxCharsForShortNotice = 250; // Was 140
    const maxLinesForShortNotice = 3;
    
    final lines = widget.notice.content.split('\n');
    return lines.length > maxLinesForShortNotice ||
        widget.notice.content.length > maxCharsForShortNotice;
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final int colorIndex = widget.notice.id % 4;
    final Color accentColor = [
      const Color(0xFF7F00FF), 
      const Color(0xFF00C853), 
      const Color(0xFFFF6D00), 
      const Color(0xFF2962FF), 
    ][colorIndex];

    final Color cardBackground = isDarkMode
        ? theme.cardTheme.color!
        : Colors.white;

    return GestureDetector(
      onTap: isLongNotice ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(isDarkMode ? 0.08 : 0.2), 
              blurRadius: isDarkMode ? 20 : 18, 
              offset: const Offset(0, 8),
            ),
            if (!isDarkMode)
               BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: accentColor.withOpacity(isDarkMode ? 0.2 : 0.15), 
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(isDarkMode ? 0.05 : 0.15), 
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: accentColor.withOpacity(0.2),
                          child: Text(
                            widget.notice.author.isNotEmpty 
                                ? widget.notice.author[0].toUpperCase() 
                                : 'A',
                            style: TextStyle(
                              color: accentColor, 
                              fontWeight: FontWeight.bold,
                              fontSize: 14
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notice.author,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.titleMedium?.color
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getRelativeTime(widget.notice.createdAt.toLocal()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isAdmin)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'delete') widget.onDelete();
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      widget.notice.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      alignment: Alignment.topCenter,
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notice.content,
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                            ),
                          ),
                          if (isLongNotice) ...[
                            const SizedBox(height: 12),
                            if (!_isExpanded)
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    accentColor,
                                    accentColor.withOpacity(0.5)
                                  ],
                                ).createShader(bounds),
                                child: Text(
                                  "Read more",
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              Text(
                                "Show less",
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}