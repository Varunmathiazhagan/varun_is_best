import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shared/chatbot_component.dart';

class ConnectPage extends StatefulWidget {
  final Map<String, dynamic>? studentData;

  const ConnectPage({Key? key, this.studentData}) : super(key: key);

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  int _selectedIndex = 2; // Connect is selected
  List<dynamic> _alumniList = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Grouped alumni by department
  Map<String, List<dynamic>> _alumniByDept = {};

  final ChatbotComponent _chatbotComponent = ChatbotComponent();

  @override
  void initState() {
    super.initState();
    _fetchAlumni();
  }

  Future<void> _fetchAlumni() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/alumni'), // Ensure this matches your backend URL
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Sort alumni by department
        data.sort(
            (a, b) => (a['department'] ?? '').compareTo(b['department'] ?? ''));

        // Group alumni by department
        final Map<String, List<dynamic>> grouped = {};
        for (var alumni in data) {
          final dept = (alumni['department'] ?? 'Unknown').toString();
          grouped.putIfAbsent(dept, () => []).add(alumni);
        }
        // Sort departments alphabetically
        final sortedKeys = grouped.keys.toList()..sort();
        final Map<String, List<dynamic>> sortedGrouped = {
          for (var k in sortedKeys) k: grouped[k]!
        };

        setState(() {
          _alumniList = data;
          _alumniByDept = sortedGrouped;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load alumni: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching alumni: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chatbotComponent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumni Connect'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _alumniList.isEmpty
                  ? const Center(child: Text('No alumni found'))
                  : _buildGroupedAlumniList(),
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
            case 1: // Discussion Forum
              Navigator.pushReplacementNamed(context, '/discussion_forum',
                  arguments: widget.studentData);
              break;
            case 2: // Connect - already here
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

  Widget _buildGroupedAlumniList() {
    List<Widget> widgets = [];
    _alumniByDept.forEach((dept, alumniList) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Text(
          dept,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
            letterSpacing: 1.2,
          ),
        ),
      ));
      for (var alumni in alumniList) {
        widgets.add(_buildAlumniCard(alumni));
      }
    });
    return ListView(
      padding: const EdgeInsets.all(12),
      children: widgets,
    );
  }

  Widget _buildAlumniCard(dynamic alumni) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            alumni['name'] != null && alumni['name'].isNotEmpty
                ? alumni['name'][0].toUpperCase()
                : '?',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
        ),
        title: Text(
          alumni['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passed Out: ${alumni['passedOutYear'] ?? 'N/A'}'),
              if (alumni['company'] != null &&
                  alumni['company'].toString().trim().isNotEmpty)
                Text('Company: ${alumni['company']}'),
            ],
          ),
        ),
        trailing: alumni['linkedin'] != null &&
                alumni['linkedin'].toString().trim().isNotEmpty
            ? IconButton(
                icon: Icon(MdiIcons.linkedin, color: Colors.blue[700]),
                tooltip: 'Open LinkedIn',
                onPressed: () {
                  // Use url_launcher in real app
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Opening LinkedIn: ${alumni['linkedin']}')),
                  );
                },
              )
            : null,
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'More Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(MdiIcons.briefcase, color: Colors.blue),
                title: const Text('Jobs & Internships'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Jobs & Internships coming soon')),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(MdiIcons.accountSupervisor, color: Colors.green),
                title: const Text('Mentoring'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Mentoring feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading:
                    const Icon(MdiIcons.calendarStar, color: Colors.orange),
                title: const Text('Events'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Events page coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(MdiIcons.robot, color: Colors.purple),
                title: const Text('Chatbot'),
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
