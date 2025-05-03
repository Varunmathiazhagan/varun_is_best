import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:alumniconnect/alumni/job_post_page.dart';
import 'package:alumniconnect/shared/job_detail_page.dart';

class JobListingsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String userType; // 'alumni' or 'student'

  const JobListingsPage({
    Key? key,
    required this.userData,
    required this.userType,
  }) : super(key: key);

  @override
  _JobListingsPageState createState() => _JobListingsPageState();
}

class _JobListingsPageState extends State<JobListingsPage> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  bool _showOnlyActiveJobs = true;
  bool _showOnlyMyJobs = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoading = true);

    try {
      String url = 'http://localhost:3000/api/jobs';
      if (_showOnlyActiveJobs) {
        url += '?active=true';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jobs = jsonDecode(response.body);

        // Filter by search query
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

        // Filter for "My Jobs" if user is alumni
        if (_showOnlyMyJobs &&
            widget.userType == 'alumni' &&
            widget.userData != null) {
          final alumniId = widget.userData!['_id'];
          jobs = jobs
              .where((job) =>
                  job['postedBy'] != null &&
                  job['postedBy']['alumniId'] == alumniId)
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

  Future<void> _deleteJob(String jobId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/jobs/$jobId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alumniId': widget.userData!['_id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job deleted successfully')),
        );
        _fetchJobs(); // Refresh the list
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete job');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToPostJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostPage(alumniData: widget.userData!),
      ),
    );

    if (result == true) {
      _fetchJobs(); // Refresh jobs if a new one was posted
    }
  }

  void _navigateToEditJob(Map<String, dynamic> jobData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobPostPage(
          alumniData: widget.userData!,
          jobData: jobData,
        ),
      ),
    );

    if (result == true) {
      _fetchJobs(); // Refresh jobs if edited
    }
  }

  void _navigateToJobDetail(Map<String, dynamic> jobData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailPage(
          jobData: jobData,
          userData: widget.userData,
          userType: widget.userType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlumni = widget.userType == 'alumni';

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
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(MdiIcons.filter),
            onSelected: (value) {
              if (value == 'active') {
                setState(() {
                  _showOnlyActiveJobs = !_showOnlyActiveJobs;
                });
                _fetchJobs();
              } else if (value == 'myJobs' && isAlumni) {
                setState(() {
                  _showOnlyMyJobs = !_showOnlyMyJobs;
                });
                _fetchJobs();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'active',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyActiveJobs
                          ? MdiIcons.checkboxMarked
                          : MdiIcons.checkboxBlankOutline,
                      color: _showOnlyActiveJobs ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Show Only Active Jobs'),
                  ],
                ),
              ),
              if (isAlumni)
                PopupMenuItem<String>(
                  value: 'myJobs',
                  child: Row(
                    children: [
                      Icon(
                        _showOnlyMyJobs
                            ? MdiIcons.checkboxMarked
                            : MdiIcons.checkboxBlankOutline,
                        color: _showOnlyMyJobs ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Show Only My Jobs'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchJobs,
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
                          _showOnlyMyJobs
                              ? 'You haven\'t posted any jobs yet'
                              : 'No jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (isAlumni && _showOnlyMyJobs)
                          ElevatedButton.icon(
                            onPressed: _navigateToPostJob,
                            icon: const Icon(MdiIcons.plus),
                            label: const Text('Post Your First Job'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      bool isMyJob = isAlumni &&
                          job['postedBy'] != null &&
                          job['postedBy']['alumniId'] ==
                              widget.userData?['_id'];

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
                              Text(
                                  'Posted by: ${job['postedBy']?['name'] ?? 'Anonymous'}'),
                            ],
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child:
                                Icon(MdiIcons.briefcase, color: Colors.white),
                          ),
                          trailing: isMyJob
                              ? PopupMenuButton<String>(
                                  icon: const Icon(MdiIcons.dotsVertical),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _navigateToEditJob(job);
                                    } else if (value == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: const Text(
                                              'Are you sure you want to delete this job posting?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteJob(job['_id']);
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () => _navigateToJobDetail(job),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                      );
                    },
                  ),
      ),
      // FAB for alumni to create new job posts
      floatingActionButton: isAlumni
          ? FloatingActionButton(
              onPressed: _navigateToPostJob,
              child: const Icon(MdiIcons.plus),
              tooltip: 'Post a Job',
            )
          : null,
    );
  }
}
