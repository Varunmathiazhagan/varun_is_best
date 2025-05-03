import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import '../shared/internship_detail_page.dart';

class StudentInternshipListingsPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentInternshipListingsPage({Key? key, required this.studentData})
      : super(key: key);

  @override
  _StudentInternshipListingsPageState createState() =>
      _StudentInternshipListingsPageState();
}

class _StudentInternshipListingsPageState
    extends State<StudentInternshipListingsPage> {
  List<dynamic> _internships = [];
  List<dynamic> _applications = [];
  bool _isLoading = true;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchInternships();
    _fetchApplications();
  }

  Future<void> _fetchInternships() async {
    setState(() => _isLoading = true);

    try {
      String url = 'http://localhost:3000/api/internships?active=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> internships = jsonDecode(response.body);

        // Filter by search query
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          internships = internships
              .where((internship) =>
                  internship['title']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()) ||
                  internship['company']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()) ||
                  internship['description']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()))
              .toList();
        }

        setState(() {
          _internships = internships;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load internships');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchApplications() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/students/${widget.studentData['_id']}/internship-applications'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _applications = jsonDecode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching applications: $e');
    }
  }

  bool _hasAppliedToInternship(String internshipId) {
    return _applications.any((app) => app['internship']['_id'] == internshipId);
  }

  String _getApplicationStatus(String internshipId) {
    final application = _applications.firstWhere(
      (app) => app['internship']['_id'] == internshipId,
      orElse: () => {
        'application': {'status': ''}
      },
    );
    return application['application']['status'] ?? '';
  }

  void _navigateToInternshipDetail(Map<String, dynamic> internshipData) async {
    final String internshipId = internshipData['_id'];
    final bool hasApplied = _hasAppliedToInternship(internshipId);
    final String applicationStatus =
        hasApplied ? _getApplicationStatus(internshipId) : '';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InternshipDetailPage(
          internshipData: internshipData,
          userData: widget.studentData,
          userType: 'student',
          hasApplied: hasApplied,
          applicationStatus: applicationStatus,
          onApply: () {
            // Refresh applications after applying
            _fetchApplications().then((_) => setState(() {}));
          },
        ),
      ),
    );

    if (result == true) {
      // Refresh the data
      _fetchApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Listings'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(MdiIcons.magnify),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Internships'),
                  content: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter internship title, company, or keywords',
                      prefixIcon: Icon(MdiIcons.magnify),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _searchQuery = null;
                        _fetchInternships();
                      },
                      child: const Text('Clear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchInternships();
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchInternships();
          await _fetchApplications();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _internships.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(MdiIcons.briefcaseSearch,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No internships found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _internships.length,
                    itemBuilder: (context, index) {
                      final internship = _internships[index];
                      final String internshipId = internship['_id'];
                      final bool hasApplied =
                          _hasAppliedToInternship(internshipId);
                      final String applicationStatus =
                          hasApplied ? _getApplicationStatus(internshipId) : '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        child: ListTile(
                          title: Text(
                            internship['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${internship['company'] ?? 'No Company'} · ${internship['location'] ?? 'Location not specified'}'),
                              const SizedBox(height: 4),
                              if (internship['duration'] != null &&
                                  internship['duration'].isNotEmpty)
                                Text('Duration: ${internship['duration']}'),
                              if (internship['stipend'] != null &&
                                  internship['stipend'].isNotEmpty)
                                Text('Stipend: ${internship['stipend']}'),
                              const SizedBox(height: 4),
                              if (hasApplied)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(applicationStatus),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatStatus(applicationStatus),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(MdiIcons.briefcaseOutline,
                                color: Colors.white),
                          ),
                          trailing: Icon(MdiIcons.chevronRight),
                          onTap: () => _navigateToInternshipDetail(internship),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'viewed':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }
}
