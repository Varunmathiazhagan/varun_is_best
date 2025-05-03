import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../shared/chatbot_component.dart';
import 'student_job_listings_page.dart';
import 'student_internship_listings_page.dart';

class StudentDashboardPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentDashboardPage({Key? key, required this.studentData})
      : super(key: key);

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _selectedIndex = 0;
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
          // Add Job Listings button
          IconButton(
            icon: Icon(MdiIcons.briefcase),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentJobListingsPage(
                    studentData: widget.studentData,
                  ),
                ),
              );
            },
            tooltip: 'Job Listings',
          ),
          // Add Internship Listings button
          IconButton(
            icon: Icon(MdiIcons.briefcaseOutline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentInternshipListingsPage(
                    studentData: widget.studentData,
                  ),
                ),
              );
            },
            tooltip: 'Internship Listings',
          ),
          IconButton(
            icon: Icon(MdiIcons.accountCircle),
            onPressed: () => Navigator.pushNamed(context, '/student_profile',
                arguments: widget.studentData),
            tooltip: 'Student Profile',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(MdiIcons.account,
                        size: 40, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.studentData['name'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    widget.studentData['konguEmail'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(MdiIcons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                // Already on home page
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.forum),
              title: Text('Discussion Forum'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/shared_discussion', arguments: {
                  'userData': widget.studentData,
                  'userType': 'student'
                });
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.accountGroup),
              title: Text('Connect'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/connect',
                    arguments: widget.studentData);
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.dotsHorizontal),
              title: Text('Others'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/others',
                    arguments: widget.studentData);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(MdiIcons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${widget.studentData['name']?.split(' ')[0] ?? 'Student'}!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Stay connected with your alumni network',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Upcoming Events section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(MdiIcons.calendarClock, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(  // Add Expanded to prevent overflow
                            child: Text(
                              'Upcoming Events',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/events');
                            },
                            child: Text('View All'),
                          ),
                        ],
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Alumni Connect 2023'),
                        subtitle: Text('Oct 15, 2023 • Main Auditorium'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Register'),
                        ),
                      ),
                      ListTile(
                        title: Text('Career Fair'),
                        subtitle: Text('Nov 10, 2023 • Virtual Event'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          child: Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Job/Internship Section - Added new section for easy access
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(MdiIcons.briefcase, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(  // Added Expanded to prevent overflow
                            child: Text(
                              'Job & Internship Opportunities',
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,  // Handle text overflow gracefully
                            ),
                          ),
                        ],
                      ),
                      Divider(),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _QuickAccessButton(
                              icon: MdiIcons.briefcase,
                              label: 'Jobs',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentJobListingsPage(
                                      studentData: widget.studentData,
                                    ),
                                  ),
                                );
                              },
                            ),
                            _QuickAccessButton(
                              icon: MdiIcons.briefcaseOutline,
                              label: 'Internships',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        StudentInternshipListingsPage(
                                      studentData: widget.studentData,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Latest Announcements
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(MdiIcons.bullhorn, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Latest Announcements',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Divider(),
                      ListTile(
                        title: Text('Student-Alumni Mentorship Program'),
                        subtitle: Text('Applications open until Sept 30, 2023'),
                        trailing: Icon(MdiIcons.arrowRight),
                        onTap: () {},
                      ),
                      ListTile(
                        title: Text('Workshop on Industry 4.0'),
                        subtitle: Text('Register before Oct 5, 2023'),
                        trailing: Icon(MdiIcons.arrowRight),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Recent Alumni Highlights
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(MdiIcons.accountGroup, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Alumni Highlights',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          child: Icon(MdiIcons.account),
                        ),
                        title: Text('Priya Sharma'),
                        subtitle:
                            Text('Secured position at Google, Mountain View'),
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          child: Icon(MdiIcons.account),
                        ),
                        title: Text('Rahul Verma'),
                        subtitle: Text('Published research paper in IEEE'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Handle navigation based on selected index
          switch (index) {
            case 0: // Home - already on dashboard
              break;
            case 1: // Discussion Forum
              Navigator.pushNamed(context, '/shared_discussion', arguments: {
                'userData': widget.studentData,
                'userType': 'student'
              });
              break;
            case 2: // Connect
              Navigator.pushNamed(context, '/connect',
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
                title: Text('Jobs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentJobListingsPage(
                        studentData: widget.studentData,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(MdiIcons.briefcaseOutline, color: Colors.green),
                title: Text('Internships'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentInternshipListingsPage(
                        studentData: widget.studentData,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(MdiIcons.accountSupervisor, color: Colors.green),
                title: Text('Mentoring'),
                onTap: () {
                  Navigator.pop(context);
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
                  Navigator.pushNamed(context, '/events');
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
              ListTile(
                leading: Icon(MdiIcons.forum, color: Colors.blue),
                title: Text('Discussion Forum'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/shared_discussion',
                      arguments: {
                        'userData': widget.studentData,
                        'userType': 'student'
                      });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom widget to create quick access buttons
class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
