import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import '../shared/chatbot_component.dart';

class StudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentProfilePage({Key? key, required this.studentData})
      : super(key: key);

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = -1; // No selection for profile page
  late TextEditingController _linkedinController;
  late TextEditingController _instagramController;
  late TextEditingController _githubController;
  late TextEditingController _phoneController;
  late TextEditingController _personalEmailController;
  late TextEditingController _departmentController;
  late TextEditingController _joiningYearController;
  late TextEditingController _passingYearController;
  final ChatbotComponent _chatbotComponent = ChatbotComponent();

  @override
  void initState() {
    super.initState();
    _linkedinController =
        TextEditingController(text: widget.studentData['linkedin'] ?? '');
    _instagramController =
        TextEditingController(text: widget.studentData['instagram'] ?? '');
    _githubController =
        TextEditingController(text: widget.studentData['github'] ?? '');
    _phoneController =
        TextEditingController(text: widget.studentData['phone'] ?? '');
    _personalEmailController =
        TextEditingController(text: widget.studentData['personalEmail'] ?? '');
    _departmentController =
        TextEditingController(text: widget.studentData['department'] ?? '');
    _joiningYearController =
        TextEditingController(text: widget.studentData['joiningYear'] ?? '');
    _passingYearController =
        TextEditingController(text: widget.studentData['passingYear'] ?? '');
  }

  @override
  void dispose() {
    _linkedinController.dispose();
    _instagramController.dispose();
    _githubController.dispose();
    _phoneController.dispose();
    _personalEmailController.dispose();
    _departmentController.dispose();
    _joiningYearController.dispose();
    _passingYearController.dispose();
    _chatbotComponent.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/student/update'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': widget.studentData['username'],
            'linkedin': _linkedinController.text,
            'instagram': _instagramController.text,
            'github': _githubController.text,
            'phone': _phoneController.text,
            'personalEmail': _personalEmailController.text,
            'department': _departmentController.text,
            'joiningYear': _joiningYearController.text,
            'passingYear': _passingYearController.text,
          }),
        );

        // Handle response
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );

          // Update the data in the parent and return
          final updatedData = Map<String, dynamic>.from(widget.studentData);
          updatedData['linkedin'] = _linkedinController.text;
          updatedData['instagram'] = _instagramController.text;
          updatedData['github'] = _githubController.text;
          updatedData['phone'] = _phoneController.text;
          updatedData['personalEmail'] = _personalEmailController.text;
          updatedData['department'] = _departmentController.text;
          updatedData['joiningYear'] = _joiningYearController.text;
          updatedData['passingYear'] = _passingYearController.text;

          Navigator.pop(context, updatedData);
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: ${data['message'] ?? "Update failed"}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alumni Connect'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Banner
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(MdiIcons.account,
                          size: 50, color: Colors.blueAccent),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.studentData['name'] ?? 'N/A',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      widget.studentData['rollNo'] ?? 'N/A',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(MdiIcons.pencil),
                          label: Text('Edit Profile'),
                          onPressed: () {
                            _showEditProfileForm();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Academic Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(MdiIcons.school, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Academic Information',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(MdiIcons.school),
                      title: Text('Department'),
                      subtitle: Text(widget.studentData['department'] ?? 'N/A'),
                    ),
                    ListTile(
                      leading: Icon(MdiIcons.calendar),
                      title: Text('Academic Period'),
                      subtitle: Text(
                          '${widget.studentData['joiningYear'] ?? 'N/A'} - ${widget.studentData['passingYear'] ?? 'N/A'}'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Contact Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(MdiIcons.phone, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Contact Information',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(MdiIcons.email),
                      title: Text('Academic Email'),
                      subtitle: Text(widget.studentData['konguEmail'] ?? 'N/A'),
                    ),
                    ListTile(
                      leading: Icon(MdiIcons.email),
                      title: Text('Personal Email'),
                      subtitle:
                          Text(widget.studentData['personalEmail'] ?? 'N/A'),
                    ),
                    ListTile(
                      leading: Icon(MdiIcons.phone),
                      title: Text('Phone'),
                      subtitle: Text(widget.studentData['phone'] ?? 'N/A'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Social Media Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(MdiIcons.web, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Social Media',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(MdiIcons.linkedin, color: Colors.blue),
                      title: Text('LinkedIn'),
                      subtitle: Text(
                          widget.studentData['linkedin'] ?? 'Not provided'),
                    ),
                    ListTile(
                      leading: Icon(MdiIcons.instagram, color: Colors.pink),
                      title: Text('Instagram'),
                      subtitle: Text(
                          widget.studentData['instagram'] ?? 'Not provided'),
                    ),
                    ListTile(
                      leading: Icon(MdiIcons.github, color: Colors.black),
                      title: Text('GitHub'),
                      subtitle:
                          Text(widget.studentData['github'] ?? 'Not provided'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Default to home for consistency
        onTap: (index) {
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

  void _showEditProfileForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  // Contact Information fields
                  TextFormField(
                    controller: _personalEmailController,
                    decoration: InputDecoration(
                      labelText: 'Personal Email',
                      prefixIcon: Icon(MdiIcons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isNotEmpty && !value.contains('@')
                            ? 'Invalid email'
                            : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(MdiIcons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Social Media fields
                  TextFormField(
                    controller: _linkedinController,
                    decoration: InputDecoration(
                      labelText: 'LinkedIn Profile',
                      prefixIcon: Icon(MdiIcons.linkedin),
                      border: OutlineInputBorder(),
                      hintText: 'linkedin.com/in/yourprofile',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _instagramController,
                    decoration: InputDecoration(
                      labelText: 'Instagram Handle',
                      prefixIcon: Icon(MdiIcons.instagram),
                      border: OutlineInputBorder(),
                      hintText: '@yourusername',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _githubController,
                    decoration: InputDecoration(
                      labelText: 'GitHub Username',
                      prefixIcon: Icon(MdiIcons.github),
                      border: OutlineInputBorder(),
                      hintText: 'github.com/yourusername',
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('CANCEL'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _updateProfile();
                            Navigator.pop(context);
                          }
                        },
                        child: Text('SAVE'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
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

  // Keep the existing _updateProfile method
}
