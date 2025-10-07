// lib/screens/notice_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../provider/auth_provider.dart';
import '../provider/notice_provider.dart';

// Light theme palettes (Background and Accent)
const List<Color> _lightCardColors = [
  Color(0xFFE7F3FF), Color(0xFFE5F8ED), Color(0xFFFFF4E5), Color(0xFFF3E5F9), Color(0xFFE0F7FA)
];
const List<Color> _lightAccentColors = [
  Color(0xFF4A90E2), Color(0xFF50E3C2), Color(0xFFF5A623), Color(0xFF9013FE), Color(0xFF00ACC1)
];

// Dark theme palettes (Background and Accent)
const List<Color> _darkCardColors = [
  Color(0xFF2A2D3A), Color(0xFF2B3A3B), Color(0xFF39322E), Color(0xFF3A2F4B), Color(0xFF2C3E4A)
];
const List<Color> _darkAccentColors = [
  Color(0xFF8AB4F8), Color(0xFF81C995), Color(0xFFFDD663), Color(0xFFC58AF9), Color(0xFF78D9EC)
];


class NoticeScreen extends StatefulWidget {
  const NoticeScreen({Key? key}) : super(key: key);

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
    await Provider.of<NoticeProvider>(context, listen: false)
        .fetchNotices(forceRefresh: true);
  }

  void _showDeleteConfirmationDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Delete Notice?'),
          content: Text(
              'Are you sure you want to delete the notice titled "${notice.title}"? This action cannot be undone.'),
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
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    final bool isAdmin =
        user?.role == 'convenor' || user?.role == 'mess_committee';
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<NoticeProvider>(
        builder: (context, noticeProvider, child) {
          if (noticeProvider.isLoading && noticeProvider.notices.isEmpty) {
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
                padding: const EdgeInsets.all(12.0),
                itemCount: noticeProvider.notices.length,
                itemBuilder: (BuildContext context, int index) {
                  final notice = noticeProvider.notices[index];
                  // Cycle through the color palettes for each card.
                  final cardColor = isDarkMode
                      ? _darkCardColors[index % _darkCardColors.length]
                      : _lightCardColors[index % _lightCardColors.length];
                  final accentColor = isDarkMode
                      ? _darkAccentColors[index % _darkAccentColors.length]
                      : _lightAccentColors[index % _lightAccentColors.length];

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: NoticeCard(
                          notice: notice,
                          isAdmin: isAdmin,
                          cardColor: cardColor,
                          accentColor: accentColor,
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
    );
  }

  Widget _buildInfoMessage({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
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
  final Color cardColor;
  final Color accentColor;
  final VoidCallback onDelete;

  const NoticeCard({
    Key? key,
    required this.notice,
    required this.isAdmin,
    required this.cardColor,
    required this.accentColor,
    required this.onDelete,
  }) : super(key: key);

  @override
  _NoticeCardState createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  bool _isExpanded = false;

  bool get isLongNotice {
    const maxCharsForShortNotice = 120;
    const maxLinesForShortNotice = 3;
    final lines = widget.notice.content.split('\n');
    return lines.length > maxLinesForShortNotice ||
        widget.notice.content.length > maxCharsForShortNotice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Define text colors based on the theme for better readability on custom backgrounds
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final metadataColor = isDarkMode ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: isLongNotice ? () => setState(() => _isExpanded = !_isExpanded) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: widget.accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCardHeader(theme, titleColor),
                        const SizedBox(height: 12),
                        _buildMetadata(theme, metadataColor),
                        const Divider(height: 24, thickness: 0.5),
                        _buildContent(theme, titleColor),
                        if (isLongNotice) _buildExpandToggle(theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(ThemeData theme, Color titleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.notice.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
        ),
        if (widget.isAdmin)
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.delete_outline,
                  color: Colors.redAccent.withOpacity(0.8)),
              onPressed: widget.onDelete,
              tooltip: 'Delete Notice',
            ),
          ),
      ],
    );
  }

  Widget _buildMetadata(ThemeData theme, Color metadataColor) {
    final metadataStyle =
        theme.textTheme.bodySmall?.copyWith(color: metadataColor);
    return Wrap(
      spacing: 16.0,
      runSpacing: 4.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 14, color: metadataColor),
            const SizedBox(width: 6),
            Text('By ${widget.notice.author}', style: metadataStyle),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: metadataColor),
            const SizedBox(width: 6),
            Text(
              DateFormat('d MMM, yyyy').format(widget.notice.createdAt.toLocal()),
              style: metadataStyle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, Color contentColor) {
    final contentStyle =
        theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: contentColor);
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState:
            _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: Text(
          widget.notice.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: contentStyle,
        ),
        secondChild: Text(
          widget.notice.content,
          style: contentStyle,
        ),
      ),
    );
  }

  Widget _buildExpandToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _isExpanded ? 'Show Less' : 'Show More',
            style: TextStyle(
                color: widget.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(width: 4),
          Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: widget.accentColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}