import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import '../shared/job_detail_page.dart';

class StudentJobListingsPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const StudentJobListingsPage({Key? key, required this.studentData})
      : super(key: key);

  @override
  _StudentJobListingsPageState createState() => _StudentJobListingsPageState();
}

class _StudentJobListingsPageState extends State<StudentJobListingsPage> {
  List<dynamic> _jobs = [];
  List<dynamic> _applications = [];
  bool _isLoading = true;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _fetchApplications();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);

    try {
      String url = 'http://localhost:3000/api/jobs?active=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jobs = jsonDecode(response.body);

        // Filter by search query if exists
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          jobs = jobs
              .where((job) =>
                  job['title']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()) ||
                  job['company']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()) ||
                  job['description']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery!.toLowerCase()))
              .toList();
        }

        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load jobs');
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
            'http://localhost:3000/api/students/${widget.studentData['_id']}/job-applications'),
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

  bool _hasAppliedToJob(String jobId) {
    return _applications.any((app) => app['job']['_id'] == jobId);
  }

  String _getApplicationStatus(String jobId) {
    final application = _applications.firstWhere(
      (app) => app['job']['_id'] == jobId,
      orElse: () => {
        'application': {'status': ''}
      },
    );
    return application['application']['status'] ?? '';
  }

  void _navigateToJobDetail(Map<String, dynamic> jobData) async {
    final String jobId = jobData['_id'];
    final bool hasApplied = _hasAppliedToJob(jobId);
    final String applicationStatus =
        hasApplied ? _getApplicationStatus(jobId) : '';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailPage(
          jobData: jobData,
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
        title: const Text('Job Listings'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(MdiIcons.magnify),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Jobs'),
                  content: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter job title, company, or keywords',
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
                        _fetchJobs();
                      },
                      child: const Text('Clear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchJobs();
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
          await _fetchJobs();
          await _fetchApplications();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(MdiIcons.briefcaseSearch,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
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
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      final String jobId = job['_id'];
                      final bool hasApplied = _hasAppliedToJob(jobId);
                      final String applicationStatus =
                          hasApplied ? _getApplicationStatus(jobId) : '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        child: ListTile(
                          title: Text(
                            job['title'] ?? 'No Title',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${job['company'] ?? 'No Company'} · ${job['location'] ?? 'Location not specified'}'),
                              const SizedBox(height: 4),
                              if (job['salary'] != null &&
                                  job['salary'].isNotEmpty)
                                Text('Salary: ${job['salary']}'),
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
                            backgroundColor: Colors.blue,
                            child:
                                Icon(MdiIcons.briefcase, color: Colors.white),
                          ),
                          trailing: Icon(MdiIcons.chevronRight),
                          onTap: () => _navigateToJobDetail(job),
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
