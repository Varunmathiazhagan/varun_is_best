import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:alumniconnect/alumni/job_listings_page.dart';
import 'package:alumniconnect/alumni/job_post_page.dart';
import 'package:alumniconnect/alumni/internship_post_page.dart';
import 'package:alumniconnect/alumni/internship_listings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class AlumniDashboardPage extends StatefulWidget {
  final Map<String, dynamic> alumniData;

  const AlumniDashboardPage({Key? key, required this.alumniData})
      : super(key: key);

  @override
  _AlumniDashboardPageState createState() => _AlumniDashboardPageState();
}

class _AlumniDashboardPageState extends State<AlumniDashboardPage> {
  int _selectedIndex = 0;
  int _alumniPoints = 150; // Placeholder for points
  int _streakDays = 3; // Placeholder for streak
  double _profileCompletion = 0.7; // 70% complete
  final List<Map<String, dynamic>> _badges = [
    {'name': 'Networker', 'icon': MdiIcons.accountNetwork},
    {'name': 'Contributor', 'icon': MdiIcons.star},
  ];

  // Add method to launch the VR tour URL
  Future<void> _launchVRTour() async {
    const url = 'https://kongu.edu/itpark360';
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open VR tour: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home (current page)
        break;
      case 1:
        // Q&A - Navigate to shared discussion forum
        Navigator.pushNamed(context, '/shared_discussion',
            arguments: {'userData': widget.alumniData, 'userType': 'alumni'});
        break;
      case 2:
        // Mentor
        break;
      case 3:
        // Show additional features
        _showAdditionalFeatures(context);
        break;
    }
  }

  void _showAdditionalFeatures(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(MdiIcons.accountEdit),
              title: Text('Update Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/alumni_profile',
                    arguments: widget.alumniData);
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.forum),
              title: Text('Discussion Forum'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/shared_discussion', arguments: {
                  'userData': widget.alumniData,
                  'userType': 'alumni'
                });
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.briefcase),
              title: Text('Jobs'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobListingsPage(
                      userData: widget.alumniData,
                      userType: 'alumni',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.briefcaseClock),
              title: Text('Internships'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InternshipListingsPage(
                      userData: widget.alumniData,
                      userType: 'alumni',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(MdiIcons.accountGroup),
              title: Text('Students'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/students');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(MdiIcons.account, color: Colors.white),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('Alumni Dashboard'),
        actions: [
          // Add VR Tour button
          ElevatedButton.icon(
            icon: Icon(MdiIcons.viewQuilt),
            label: Text('Visit Your College'),
            onPressed: _launchVRTour,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
          ),
          // Add job posting shortcut
          IconButton(
            icon: Icon(MdiIcons.briefcasePlus),
            tooltip: 'Post a Job',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobPostPage(
                    alumniData: widget.alumniData,
                  ),
                ),
              );
            },
          ),
          // Add internship posting shortcut
          IconButton(
            icon: Icon(MdiIcons.briefcaseClockOutline),
            tooltip: 'Post an Internship',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InternshipPostPage(
                    alumniData: widget.alumniData,
                  ),
                ),
              );
            },
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
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(MdiIcons.accountStar,
                        size: 50, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.alumniData['name'] ?? 'N/A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.alumniData['email'] ?? 'N/A',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Points: $_alumniPoints',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(MdiIcons.numeric),
              title:
                  Text('Roll Number: ${widget.alumniData['rollNo'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.school),
              title: Text(
                  'Department: ${widget.alumniData['department'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.calendarCheck),
              title: Text(
                  'Passed Out Year: ${widget.alumniData['passedOutYear'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.briefcase),
              title: Text('Company: ${widget.alumniData['company'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.linkedin),
              title:
                  Text('LinkedIn: ${widget.alumniData['linkedin'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.phone),
              title: Text('Phone: ${widget.alumniData['phone'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.email),
              title: Text(
                  'Other Email: ${widget.alumniData['otherEmail'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.mapMarker),
              title: Text('Address: ${widget.alumniData['address'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: Icon(MdiIcons.trophy),
              title: Text('Badges: ${_badges.length}'),
              onTap: () {
                // Show badges page
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Message & Gamification Stats
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${widget.alumniData['name'] ?? 'Alumni'}!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Class of ${widget.alumniData['passedOutYear'] ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Points: $_alumniPoints'),
                                  Text('Streak: $_streakDays days'),
                                ],
                              ),
                              Row(
                                children: _badges
                                    .map((badge) => Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(badge['icon'],
                                              color: Colors.amber, size: 24),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Profile Completion Progress Bar
                          Text('Profile Completion'),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _profileCompletion,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent),
                          ),
                          SizedBox(height: 8),
                          Text(
                              '${(_profileCompletion * 100).toInt()}% Complete'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Personalized Action Recommendations
                  Text(
                    'Recommended for You',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _RecommendationCard(
                    message: _profileCompletion < 1.0
                        ? 'Complete your profile to unlock more features!'
                        : '', // Remove event message
                    actionText: _profileCompletion < 1.0
                        ? 'Update Profile'
                        : '', // Remove event action
                    onPressed: () {
                      Navigator.pushNamed(context, '/alumni_profile',
                          arguments: widget.alumniData);
                    },
                  ),
                  SizedBox(height: 16),
                  // Alumni Spotlight
                  Text(
                    'Alumni Spotlight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(
                    height: 180, // Increase height to accommodate content
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _SpotlightCard(
                          name: 'Jane Doe',
                          achievement: 'Promoted to CTO at TechCorp',
                          linkedin: 'linkedin.com/in/janedoe',
                          onTap: () {
                            // Navigate to alumni profile
                          },
                        ),
                        SizedBox(width: 8),
                        _SpotlightCard(
                          name: 'John Smith',
                          achievement: 'Published a book on AI',
                          linkedin: 'linkedin.com/in/johnsmith',
                          onTap: () {
                            // Navigate to alumni profile
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Interactive Poll
                  Text(
                    'Weekly Poll',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _PollCard(
                    question: 'Which industry are you most interested in?',
                    options: ['Tech', 'Finance', 'Healthcare', 'Others'],
                    onVote: (index) {
                      // Handle vote (e.g., send to backend)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vote submitted!')),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  // Memory Lane
                  Text(
                    'Memory Lane',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _MemoryCard(
                    memory:
                        'In ${widget.alumniData['passedOutYear'] ?? '2015'}, your department won the inter-college tech fest!',
                  ),
                  SizedBox(height: 16),
                  // Quick Links
                  Text(
                    'Quick Links',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickLinkTile(
                        icon: MdiIcons.forum,
                        label: 'Q&A',
                        onTap: () {
                          // Navigate to Q&A
                        },
                      ),
                      _QuickLinkTile(
                        icon: MdiIcons.accountSupervisor,
                        label: 'Mentor',
                        onTap: () {
                          // Navigate to Mentor
                        },
                      ),
                      _QuickLinkTile(
                        icon: MdiIcons.briefcase,
                        label: 'Jobs',
                        onTap: () {
                          // Navigate to Jobs
                        },
                      ),
                      _QuickLinkTile(
                        icon: MdiIcons.accountEdit,
                        label: 'Profile',
                        onTap: () {
                          Navigator.pushNamed(context, '/alumni_profile',
                              arguments: widget.alumniData);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Recent Announcements
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Announcements',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to full announcements page
                        },
                        child: Text('View All'),
                      ),
                    ],
                  ),
                  _AnnouncementCard(
                    title: 'New Scholarship Program',
                    date: 'May 1, 2025',
                    description:
                        'Introducing a new scholarship for current students.',
                  ),
                  SizedBox(height: 16),
                  // Recent Discussions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Discussions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to full discussions page
                        },
                        child: Text('View All'),
                      ),
                    ],
                  ),
                  _DiscussionCard(
                    title: 'Career Transition Tips',
                    author: 'John Smith',
                    replies: 12,
                    onTap: () {
                      // Navigate to discussion thread
                    },
                  ),
                  SizedBox(height: 16),
                  // Removed Job Opportunities section
                  // Removed Connect with Alumni section
                ],
              ),
            )
          : Center(child: Text('Coming Soon')), // Placeholder for other tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.forum),
            label: 'Q&A',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.accountSupervisor),
            label: 'Mentor',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.dotsGrid),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// Widget for Quick Link Tiles
class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: Icon(icon, color: Colors.blueAccent),
          ),
          SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// Widget for Announcement Cards
class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;

  const _AnnouncementCard({
    required this.title,
    required this.date,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date),
            SizedBox(height: 4),
            Text(description),
          ],
        ),
        leading: Icon(MdiIcons.bullhorn, color: Colors.blueAccent),
      ),
    );
  }
}

// Widget for Discussion Cards
class _DiscussionCard extends StatelessWidget {
  final String title;
  final String author;
  final int replies;
  final VoidCallback onTap;

  const _DiscussionCard({
    required this.title,
    required this.author,
    required this.replies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('Started by $author · $replies replies'),
        leading: Icon(MdiIcons.forumOutline, color: Colors.blueAccent),
        onTap: onTap,
      ),
    );
  }
}

// Widget for Job Cards
class _JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final VoidCallback onTap;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('$company · $location'),
        leading: Icon(MdiIcons.briefcase, color: Colors.blueAccent),
        onTap: onTap,
      ),
    );
  }
}

// Widget for Networking Cards
class _NetworkingCard extends StatelessWidget {
  final String name;
  final String company;
  final String department;
  final VoidCallback onTap;

  const _NetworkingCard({
    required this.name,
    required this.company,
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('$company · $department'),
        leading: CircleAvatar(child: Text(name[0])),
        trailing: IconButton(
          icon: Icon(MdiIcons.accountPlus, color: Colors.blueAccent),
          onPressed: onTap,
        ),
      ),
    );
  }
}

// Widget for Recommendation Cards
class _RecommendationCard extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onPressed;

  const _RecommendationCard({
    required this.message,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(MdiIcons.lightbulbOn, color: Colors.amber),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onPressed,
                    child: Text(actionText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Spotlight Cards
class _SpotlightCard extends StatelessWidget {
  final String name;
  final String achievement;
  final String linkedin;
  final VoidCallback onTap;

  const _SpotlightCard({
    required this.name,
    required this.achievement,
    required this.linkedin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 220,
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(name[0])),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: Text(
                achievement,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              linkedin,
              style: TextStyle(color: Colors.blue),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(MdiIcons.accountDetails, size: 16),
              label: Text('View Profile'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size(0, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for Poll Cards
class _PollCard extends StatelessWidget {
  final String question;
  final List<String> options;
  final Function(int) onVote;

  const _PollCard({
    required this.question,
    required this.options,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              int index = entry.key;
              String option = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () => onVote(index),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(option),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// Widget for Memory Cards
class _MemoryCard extends StatelessWidget {
  final String memory;

  const _MemoryCard({
    required this.memory,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(MdiIcons.history, color: Colors.blueAccent),
            SizedBox(width: 16),
            Expanded(child: Text(memory)),
          ],
        ),
      ),
    );
  }
}
