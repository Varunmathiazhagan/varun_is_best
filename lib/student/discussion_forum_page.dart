import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../shared/chatbot_component.dart';
import '../shared/discussion_forum_shared_page.dart';

class DiscussionForumPage extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const DiscussionForumPage({Key? key, this.studentData}) : super(key: key);

  @override
  State<DiscussionForumPage> createState() => _DiscussionForumPageState();
}

class _DiscussionForumPageState extends State<DiscussionForumPage> {
  int _selectedIndex = 1; // Discussion forum is selected
  final ChatbotComponent _chatbotComponent = ChatbotComponent();

  @override
  void dispose() {
    _chatbotComponent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the shared discussion forum page implementation
    if (widget.studentData != null) {
      return DiscussionForumSharedPage(
        userData: widget.studentData,
        userType: 'student',
      );
    }

    // Fallback to placeholder if no student data
    return Scaffold(
      appBar: AppBar(
        title: Text('Alumni Connect'),
        actions: [
          IconButton(
            icon: Icon(MdiIcons.accountCircle),
            onPressed: () {
              if (widget.studentData != null) {
                Navigator.pushNamed(context, '/student_profile',
                    arguments: widget.studentData);
              }
            },
            tooltip: 'Student Profile',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.forum, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              'Discussion Forum',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            Text(
              'You need to log in to access this feature.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (widget.studentData == null) return;

          // Avoid re-navigation to the same page
          if (index == _selectedIndex && index != 3) return;

          setState(() {
            _selectedIndex = index;
          });

          // Handle navigation based on selected index
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/student_dashboard',
                  arguments: widget.studentData);
              break;
            case 1: // Discussion Forum - already here
              break;
            case 2: // Connect
              Navigator.pushReplacementNamed(context, '/connect',
                  arguments: widget.studentData);
              break;
            case 3: // More
              _showMoreOptions(context);
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.forum),
            label: 'Discuss',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.accountGroup),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.dotsHorizontal),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'More Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Divider(),
              ListTile(
                leading: Icon(MdiIcons.briefcase, color: Colors.blue),
                title: Text('Jobs & Internships'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to jobs page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jobs & Internships coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(MdiIcons.accountSupervisor, color: Colors.green),
                title: Text('Mentoring'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to mentoring page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mentoring feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(MdiIcons.calendarStar, color: Colors.orange),
                title: Text('Events'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to events page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Events page coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(MdiIcons.robot, color: Colors.purple),
                title: Text('Chatbot'),
                onTap: () {
                  Navigator.pop(context);
                  _chatbotComponent.openChatBotDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
