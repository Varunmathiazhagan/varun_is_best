import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class JobDetailPage extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final Map<String, dynamic>? userData;
  final String userType; // 'alumni' or 'student'
  final bool hasApplied; // For student: has applied to this job
  final String applicationStatus; // For student: application status
  final VoidCallback? onApply; // Callback when student applies

  const JobDetailPage({
    Key? key,
    required this.jobData,
    required this.userData,
    required this.userType,
    this.hasApplied = false,
    this.applicationStatus = '',
    this.onApply,
  }) : super(key: key);

  @override
  _JobDetailPageState createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  @override
  Widget build(BuildContext context) {
    final bool isMyJob = widget.userType == 'alumni' &&
        widget.userData != null &&
        widget.jobData['postedBy'] != null &&
        widget.jobData['postedBy']['alumniId'] == widget.userData!['_id'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job title and company
            Text(
              widget.jobData['title'] ?? 'No Title',
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
                  widget.jobData['company'] ?? 'No Company',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (widget.jobData['location'] != null &&
                widget.jobData['location'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(MdiIcons.mapMarker, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.jobData['location'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Job details
            Text(
              'Job Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.jobData['description'] ?? 'No description available.'),

            if (widget.jobData['requirements'] != null &&
                widget.jobData['requirements'].isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.jobData['requirements']),
            ],

            const SizedBox(height: 24),
            Text(
              'Additional Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // Salary
            if (widget.jobData['salary'] != null &&
                widget.jobData['salary'].isNotEmpty) ...[
              ListTile(
                leading: const Icon(MdiIcons.currencyInr),
                title: const Text('Salary'),
                subtitle: Text(widget.jobData['salary']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Posted by
            if (widget.jobData['postedBy'] != null &&
                widget.jobData['postedBy']['name'] != null) ...[
              ListTile(
                leading: const Icon(MdiIcons.account),
                title: const Text('Posted by'),
                subtitle: Text(widget.jobData['postedBy']['name']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Expiry date
            if (widget.jobData['expiresAt'] != null) ...[
              ListTile(
                leading: const Icon(MdiIcons.calendar),
                title: const Text('Valid until'),
                subtitle: Text(
                  DateTime.parse(widget.jobData['expiresAt'])
                      .toLocal()
                      .toString()
                      .split(' ')[0],
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            // Contact email
            if (widget.jobData['contactEmail'] != null &&
                widget.jobData['contactEmail'].isNotEmpty) ...[
              ListTile(
                leading: const Icon(MdiIcons.email),
                title: const Text('Contact Email'),
                subtitle: Text(widget.jobData['contactEmail']),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: 32),

            // Application button
            if (widget.jobData['applicationLink'] != null &&
                widget.jobData['applicationLink'].isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: widget.onApply,
                  icon: const Icon(MdiIcons.openInNew),
                  label: const Text('Apply Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
