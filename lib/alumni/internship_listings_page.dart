import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:alumniconnect/alumni/internship_post_page.dart';
import 'package:alumniconnect/shared/internship_detail_page.dart';

class InternshipListingsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String userType; // 'alumni' or 'student'

  const InternshipListingsPage({
    Key? key,
    required this.userData,
    required this.userType,
  }) : super(key: key);

  @override
  _InternshipListingsPageState createState() => _InternshipListingsPageState();
}

class _InternshipListingsPageState extends State<InternshipListingsPage> {
  List<dynamic> _internships = [];
  bool _isLoading = true;
  bool _showOnlyActiveInternships = true;
  bool _showOnlyMyInternships = false;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _fetchInternships();
  }

  Future<void> _fetchInternships() async {
    setState(() => _isLoading = true);

    try {
      String url = 'http://localhost:3000/api/internships';
      if (_showOnlyActiveInternships) {
        url += '?active=true';
      }

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

        // Filter for "My Internships" if user is alumni
        if (_showOnlyMyInternships &&
            widget.userType == 'alumni' &&
            widget.userData != null) {
          final alumniId = widget.userData!['_id'];
          internships = internships
              .where((internship) =>
                  internship['postedBy'] != null &&
                  internship['postedBy']['alumniId'] == alumniId)
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

  Future<void> _deleteInternship(String internshipId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/internships/$internshipId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'alumniId': widget.userData!['_id']}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internship deleted successfully')),
        );
        _fetchInternships(); // Refresh the list
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete internship');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToPostInternship() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InternshipPostPage(alumniData: widget.userData!),
      ),
    );

    if (result == true) {
      _fetchInternships(); // Refresh internships if a new one was posted
    }
  }

  void _navigateToEditInternship(Map<String, dynamic> internshipData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InternshipPostPage(
          alumniData: widget.userData!,
          internshipData: internshipData,
        ),
      ),
    );

    if (result == true) {
      _fetchInternships(); // Refresh internships if edited
    }
  }

  void _navigateToInternshipDetail(Map<String, dynamic> internshipData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InternshipDetailPage(
          internshipData: internshipData,
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
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(MdiIcons.filter),
            onSelected: (value) {
              if (value == 'active') {
                setState(() {
                  _showOnlyActiveInternships = !_showOnlyActiveInternships;
                });
                _fetchInternships();
              } else if (value == 'myInternships' && isAlumni) {
                setState(() {
                  _showOnlyMyInternships = !_showOnlyMyInternships;
                });
                _fetchInternships();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'active',
                child: Row(
                  children: [
                    Icon(
                      _showOnlyActiveInternships
                          ? MdiIcons.checkboxMarked
                          : MdiIcons.checkboxBlankOutline,
                      color: _showOnlyActiveInternships
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Show Only Active Internships'),
                  ],
                ),
              ),
              if (isAlumni)
                PopupMenuItem<String>(
                  value: 'myInternships',
                  child: Row(
                    children: [
                      Icon(
                        _showOnlyMyInternships
                            ? MdiIcons.checkboxMarked
                            : MdiIcons.checkboxBlankOutline,
                        color:
                            _showOnlyMyInternships ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Show Only My Internships'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInternships,
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
                          _showOnlyMyInternships
                              ? 'You haven\'t posted any internships yet'
                              : 'No internships found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (isAlumni && _showOnlyMyInternships)
                          ElevatedButton.icon(
                            onPressed: _navigateToPostInternship,
                            icon: const Icon(MdiIcons.plus),
                            label: const Text('Post Your First Internship'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _internships.length,
                    itemBuilder: (context, index) {
                      final internship = _internships[index];
                      bool isMyInternship = isAlumni &&
                          internship['postedBy'] != null &&
                          internship['postedBy']['alumniId'] ==
                              widget.userData?['_id'];

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
                              const SizedBox(height: 4),
                              if (internship['stipend'] != null &&
                                  internship['stipend'].isNotEmpty)
                                Text('Stipend: ${internship['stipend']}'),
                              const SizedBox(height: 4),
                              Text(
                                  'Posted by: ${internship['postedBy']?['name'] ?? 'Anonymous'}'),
                            ],
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(MdiIcons.briefcaseOutline,
                                color: Colors.white),
                          ),
                          trailing: isMyInternship
                              ? PopupMenuButton<String>(
                                  icon: const Icon(MdiIcons.dotsVertical),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _navigateToEditInternship(internship);
                                    } else if (value == 'delete') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: const Text(
                                              'Are you sure you want to delete this internship posting?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteInternship(
                                                    internship['_id']);
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
                          onTap: () => _navigateToInternshipDetail(internship),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                      );
                    },
                  ),
      ),
      // FAB for alumni to create new internship posts
      floatingActionButton: isAlumni
          ? FloatingActionButton(
              onPressed: _navigateToPostInternship,
              child: const Icon(MdiIcons.plus),
              tooltip: 'Post an Internship',
            )
          : null,
    );
  }
}
