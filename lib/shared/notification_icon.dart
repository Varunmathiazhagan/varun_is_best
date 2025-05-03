import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/notification_service.dart';
import 'dart:async';

class NotificationIcon extends StatefulWidget {
  final String userId;
  final Function(List<dynamic>) onNotificationsUpdated;

  const NotificationIcon({
    Key? key,
    required this.userId,
    required this.onNotificationsUpdated,
  }) : super(key: key);

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    // Set up timer to refresh notifications every minute
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifications =
          await _notificationService.getNotifications(widget.userId);
      final unreadCount = notifications.where((n) => n['read'] == false).length;

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
      });

      widget.onNotificationsUpdated(notifications);
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _showNotifications(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(MdiIcons.bell),
            SizedBox(width: 8),
            Text('Notifications'),
            Spacer(),
            if (_unreadCount > 0)
              TextButton(
                child: Text('Mark all as read'),
                onPressed: () async {
                  await _notificationService.markAllAsRead(widget.userId);
                  await _fetchNotifications();
                  Navigator.pop(context);
                  _showNotifications(context); // Reopen with updated data
                },
              ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: _notifications.isEmpty
              ? Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['read'] ?? false;

                    String message = '';
                    IconData iconData;

                    switch (notification['type']) {
                      case 'like':
                        message =
                            '${notification['sender']} liked your question "${notification['questionTitle']}"';
                        iconData = MdiIcons.thumbUp;
                        break;
                      case 'comment':
                        message =
                            '${notification['sender']} commented on your question "${notification['questionTitle']}"';
                        iconData = MdiIcons.comment;
                        break;
                      case 'answer':
                        message =
                            '${notification['sender']} answered your question "${notification['questionTitle']}"';
                        iconData = MdiIcons.reply;
                        break;
                      default:
                        message = 'You have a new notification';
                        iconData = MdiIcons.bell;
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isRead ? Colors.grey[300] : Colors.blue,
                        child: Icon(iconData,
                            color: isRead ? Colors.grey[600] : Colors.white),
                      ),
                      title: Text(message),
                      subtitle: Text(_formatDate(notification['timestamp'])),
                      onTap: () async {
                        if (!isRead) {
                          await _notificationService
                              .markAsRead(notification['_id']);
                        }

                        // Navigate to the question
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/shared_discussion',
                            arguments: {
                              'questionId': notification['questionId'],
                              // Pass other required data
                            });
                      },
                      tileColor: isRead ? null : Colors.blue.withOpacity(0.1),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(MdiIcons.bell),
          onPressed: () => _showNotifications(context),
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
