import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;

class JobPostPage extends StatefulWidget {
  final Map<String, dynamic> alumniData;
  final Map<String, dynamic>? jobData; // Pass existing job data for editing

  const JobPostPage({
    Key? key,
    required this.alumniData,
    this.jobData,
  }) : super(key: key);

  @override
  _JobPostPageState createState() => _JobPostPageState();
}

class _JobPostPageState extends State<JobPostPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditing = false;
  DateTime? _expiryDate;

  // Form controllers
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _salaryController = TextEditingController();
  final _applicationLinkController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Check if we're editing an existing job
    if (widget.jobData != null) {
      _isEditing = true;
      _titleController.text = widget.jobData!['title'] ?? '';
      _companyController.text = widget.jobData!['company'] ?? '';
      _locationController.text = widget.jobData!['location'] ?? '';
      _descriptionController.text = widget.jobData!['description'] ?? '';
      _requirementsController.text = widget.jobData!['requirements'] ?? '';
      _salaryController.text = widget.jobData!['salary'] ?? '';
      _applicationLinkController.text =
          widget.jobData!['applicationLink'] ?? '';
      _contactEmailController.text = widget.jobData!['contactEmail'] ?? '';

      // Parse the expiry date if it exists
      if (widget.jobData!['expiresAt'] != null) {
        try {
          _expiryDate = DateTime.parse(widget.jobData!['expiresAt']);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    } else {
      // Default company and email for new job posts
      _companyController.text = widget.alumniData['company'] ?? '';
      _contactEmailController.text = widget.alumniData['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _salaryController.dispose();
    _applicationLinkController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final url = _isEditing
            ? Uri.parse(
                'http://localhost:3000/api/jobs/${widget.jobData!['_id']}')
            : Uri.parse('http://localhost:3000/api/jobs');

        final jobData = {
          'title': _titleController.text,
          'company': _companyController.text,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'requirements': _requirementsController.text,
          'salary': _salaryController.text,
          'applicationLink': _applicationLinkController.text,
          'contactEmail': _contactEmailController.text,
          'postedBy': {
            'name': widget.alumniData['name'],
            'alumniId': widget.alumniData['_id'],
          },
        };

        if (_expiryDate != null) {
          jobData['expiresAt'] = _expiryDate!.toIso8601String();
        }

        final response = _isEditing
            ? await http.put(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(jobData),
              )
            : await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(jobData),
              );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing
                    ? 'Job updated successfully'
                    : 'Job posted successfully')),
          );
          Navigator.pop(context, true); // Return success
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to submit job');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Job Posting' : 'Post a Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Job Details' : 'Job Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.briefcase),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Company
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.domain),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (e.g., Remote, Chennai, Bangalore)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.mapMarker),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.text),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Requirements
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.clipboardList),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Salary
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.currencyInr),
                ),
              ),
              const SizedBox(height: 12),

              // Application Link
              TextFormField(
                controller: _applicationLinkController,
                decoration: const InputDecoration(
                  labelText: 'Application Link/Website',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.link),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Email
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a contact email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry Date Picker
              ListTile(
                title: const Text('Job Listing Expiry Date'),
                subtitle: Text(_expiryDate == null
                    ? 'Default: 30 days from today'
                    : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
                leading: const Icon(MdiIcons.calendar),
                trailing: IconButton(
                  icon: const Icon(MdiIcons.calendarEdit),
                  onPressed: _selectExpiryDate,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _submitJob,
                        icon: Icon(
                            _isEditing ? MdiIcons.contentSave : MdiIcons.send),
                        label: Text(_isEditing ? 'Update Job' : 'Post Job'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                '* Required fields',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
