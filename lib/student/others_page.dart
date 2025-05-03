import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../shared/chatbot_component.dart';
import 'student_job_listings_page.dart';
import 'student_internship_listings_page.dart';

class OthersPage extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const OthersPage({Key? key, this.studentData}) : super(key: key);

  @override
  _OthersPageState createState() => _OthersPageState();
}

class _OthersPageState extends State<OthersPage> {
  final ChatbotComponent _chatbotComponent = ChatbotComponent();

  @override
  void dispose() {
    _chatbotComponent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(MdiIcons.briefcase, color: Colors.blue, size: 32),
            title: Text('Jobs & Internships',
                style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Find opportunities that match your skills'),
            onTap: () {
              // Show dialog to choose between jobs and internships
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Select Opportunity Type'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(MdiIcons.briefcase, color: Colors.blue),
                        title: Text('Jobs'),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.studentData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentJobListingsPage(
                                  studentData: widget.studentData!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(MdiIcons.briefcaseOutline,
                            color: Colors.green),
                        title: Text('Internships'),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.studentData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentInternshipListingsPage(
                                  studentData: widget.studentData!,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text('CANCEL'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(),
          ListTile(
            leading:
                Icon(MdiIcons.accountSupervisor, color: Colors.green, size: 32),
            title: Text('Mentoring',
                style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Connect with alumni mentors for guidance'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mentoring feature coming soon')),
              );
            },
          ),
          Divider(),
          ListTile(
            leading:
                Icon(MdiIcons.calendarStar, color: Colors.orange, size: 32),
            title:
                Text('Events', style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Upcoming alumni events and gatherings'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Events page coming soon')),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(MdiIcons.robot, color: Colors.purple, size: 32),
            title:
                Text('Chatbot', style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Get quick answers to common questions'),
            onTap: () {
              _chatbotComponent.openChatBotDialog(context);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // More is selected
        onTap: (index) {
          if (widget.studentData == null) return;

          // Avoid re-navigation to the same page
          if (index == 3) return;

          // Handle navigation based on selected index
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/student_dashboard',
                  arguments: widget.studentData);
              break;
            case 1: // Discussion Forum
              Navigator.pushReplacementNamed(context, '/discussion_forum',
                  arguments: widget.studentData);
              break;
            case 2: // Connect
              Navigator.pushReplacementNamed(context, '/connect',
                  arguments: widget.studentData);
              break;
            case 3: // More - already here
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
}
