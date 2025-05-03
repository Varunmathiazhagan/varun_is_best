import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
// Add this import for XFile and ImagePicker

class InternshipDetailPage extends StatefulWidget {
  final Map<String, dynamic> internshipData;
  final Map<String, dynamic>? userData;
  final String userType; // 'alumni' or 'student'
  final bool hasApplied; // For student: has applied to this internship
  final String applicationStatus; // For student: application status
  final VoidCallback? onApply; // Callback when student applies

  const InternshipDetailPage({
    Key? key,
    required this.internshipData,
    required this.userData,
    required this.userType,
    this.hasApplied = false,
    this.applicationStatus = '',
    this.onApply,
  }) : super(key: key);

  @override
  _InternshipDetailPageState createState() => _InternshipDetailPageState();
}

class _InternshipDetailPageState extends State<InternshipDetailPage> {
  bool _isLoading = false;
  List<dynamic> _applications = [];
  bool _loadingApplications = false;

  final TextEditingController _coverLetterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.userType == 'alumni') {
      _fetchApplications();
    }
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    if (widget.userData == null) return;

    setState(() => _loadingApplications = true);

    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3000/api/internships/${widget.internshipData['_id']}/applications?alumniId=${widget.userData!['_id']}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _applications = jsonDecode(response.body);
          _loadingApplications = false;
        });
      } else {
        throw Exception('Failed to load applications');
      }
    } catch (e) {
      setState(() => _loadingApplications = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading applications: $e')),
      );
    }
  }

  Future<void> _updateApplicationStatus(
      String applicationId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse(
            'http://localhost:3000/api/internships/applications/$applicationId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'alumniId': widget.userData!['_id'],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application status updated to $status')),
        );
        _fetchApplications(); // Refresh the applications list
      } else {
        throw Exception('Failed to update application status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _applyForInternship() async {
    if (widget.userData == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
            'http://localhost:3000/api/internships/${widget.internshipData['_id']}/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentId': widget.userData!['_id'],
          'studentName': widget.userData!['name'],
          'studentEmail':
              widget.userData!['konguEmail'] ?? widget.userData!['email'],
          'studentDepartment': widget.userData!['department'],
          'studentRollNo': widget.userData!['rollNo'],
          'coverLetter': _coverLetterController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
        Navigator.pop(context); // Close the application dialog

        if (widget.onApply != null) {
          widget.onApply!();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to apply for internship');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showApplicationForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apply for ${widget.internshipData['title']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'At ${widget.internshipData['company']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cover Letter / Message to Recruiter',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _coverLetterController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        'Tell the recruiter why you\'re interested in this position and why you\'d be a good fit...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _applyForInternship,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('SUBMIT APPLICATION'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMyInternship = widget.userType == 'alumni' &&
        widget.userData != null &&
        widget.internshipData['postedBy'] != null &&
        widget.internshipData['postedBy']['alumniId'] ==
            widget.userData!['_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Internship Details'),
        actions: [
          if (isMyInternship)
            IconButton(
              icon: const Icon(MdiIcons.accountMultiple),
              tooltip: 'View Applicants',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => _ApplicationsList(
                    applications: _applications,
                    isLoading: _loadingApplications,
                    onUpdateStatus: _updateApplicationStatus,
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internship title and company
            Text(
              widget.internshipData['title'] ?? 'No Title',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(MdiIcons.domain, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.internshipData['company'] ?? 'No Company',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (widget.internshipData['location'] != null &&
                widget.internshipData['location'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(MdiIcons.mapMarker, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.internshipData['location'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Application status for students
            if (widget.userType == 'student' && widget.hasApplied) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.applicationStatus)
                      .withOpacity(0.1), // Fix deprecated warning
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getStatusColor(widget.applicationStatus),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(widget.applicationStatus),
                          color: _getStatusColor(widget.applicationStatus),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application Status: ${_formatStatus(widget.applicationStatus)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.applicationStatus),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_getStatusMessage(widget.applicationStatus)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            const SizedBox(height: 16),

            // Internship details
            Text(
              'Internship Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.internshipData['description'] ??
                'No description available.'),

            if (widget.internshipData['requirements'] != null &&
                widget.internshipData['requirements'].isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.internshipData['requirements']),
            ],

            const SizedBox(height: 24),
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // Duration
            if (widget.internshipData['duration'] != null &&
                widget.internshipData['duration'].isNotEmpty) ...[
              ListTile(
                leading: const Icon(MdiIcons.clock),
                title: const Text('Duration'),
                subtitle: Text(widget.internshipData['duration']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Stipend
            if (widget.internshipData['stipend'] != null &&
                widget.internshipData['stipend'].isNotEmpty) ...[
              ListTile(
                leading: const Icon(MdiIcons.currencyInr),
                title: const Text('Stipend'),
                subtitle: Text(widget.internshipData['stipend']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Posted by
            if (widget.internshipData['postedBy'] != null &&
                widget.internshipData['postedBy']['name'] != null) ...[
              ListTile(
                leading: const Icon(MdiIcons.account),
                title: const Text('Posted by'),
                subtitle: Text(widget.internshipData['postedBy']['name']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Expiry date
            if (widget.internshipData['expiresAt'] != null) ...[
              ListTile(
                leading: const Icon(MdiIcons.calendar),
                title: const Text('Valid until'),
                subtitle: Text(
                  DateTime.parse(widget.internshipData['expiresAt'])
                      .toLocal()
                      .toString()
                      .split(' ')[0],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Contact email
            if (widget.internshipData['contactEmail'] != null &&
                widget.internshipData['contactEmail'].isNotEmpty) ...[
              ListTile(
                leading: const Icon(MdiIcons.email),
                title: const Text('Contact Email'),
                subtitle: Text(widget.internshipData['contactEmail']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: 32),

            // Application button for students
            if (widget.userType == 'student')
              Center(
                child: widget.hasApplied
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(MdiIcons.check),
                        label: const Text('Applied'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _showApplicationForm,
                        icon: const Icon(MdiIcons.send),
                        label: const Text('Apply Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
              ),

            // Application link for external application
            if (widget.internshipData['applicationLink'] != null &&
                widget.internshipData['applicationLink'].isNotEmpty &&
                !widget.hasApplied)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // URL launcher could be used here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Opening external link: ${widget.internshipData['applicationLink']}')),
                    );
                  },
                  icon: const Icon(MdiIcons.openInNew),
                  label: const Text('Apply on Company Site'),
                ),
              ),
          ],
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return MdiIcons.clockOutline;
      case 'viewed':
        return MdiIcons.eyeOutline;
      case 'accepted':
        return MdiIcons.checkBold;
      case 'rejected':
        return MdiIcons.close;
      default:
        return MdiIcons.helpCircleOutline;
    }
  }

  String _formatStatus(String status) {
    return status.isEmpty
        ? 'Unknown'
        : status.substring(0, 1).toUpperCase() + status.substring(1);
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your application is being reviewed by the employer.';
      case 'viewed':
        return 'Your application has been viewed by the employer.';
      case 'accepted':
        return 'Congratulations! Your application has been accepted.';
      case 'rejected':
        return 'Unfortunately, your application was not successful this time.';
      default:
        return 'Application status unknown.';
    }
  }
}

class _ApplicationsList extends StatelessWidget {
  final List<dynamic> applications;
  final bool isLoading;
  final Function(String, String) onUpdateStatus;

  const _ApplicationsList({
    Key? key,
    required this.applications,
    required this.isLoading,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applications (${applications.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : applications.isEmpty
                    ? const Center(child: Text('No applications yet'))
                    : ListView.builder(
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final application = applications[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(
                                    application['status'] ?? 'pending'),
                                child: Text(
                                  application['studentName']?.substring(0, 1) ??
                                      'S',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title:
                                  Text(application['studentName'] ?? 'No Name'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${application['studentDepartment'] ?? 'No Department'} - ${application['studentRollNo'] ?? 'No Roll No'}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                          application['status'] ?? 'pending'),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatStatus(
                                          application['status'] ?? 'pending'),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cover Letter:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(application['coverLetter'] ??
                                          'No cover letter provided.'),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Contact Information:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      ListTile(
                                        leading: const Icon(Icons.email),
                                        title: Text(
                                            application['studentEmail'] ??
                                                'No email provided'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Update Application Status:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => onUpdateStatus(
                                                application['_id'], 'viewed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                            ),
                                            child: const Text('Mark as Viewed'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => onUpdateStatus(
                                                application['_id'], 'accepted'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            child: const Text('Accept'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => onUpdateStatus(
                                                application['_id'], 'rejected'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Reject'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
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
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }
}
