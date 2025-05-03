import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;

class InternshipPostPage extends StatefulWidget {
  final Map<String, dynamic> alumniData;
  final Map<String, dynamic>?
      internshipData; // Pass existing internship data for editing

  const InternshipPostPage({
    Key? key,
    required this.alumniData,
    this.internshipData,
  }) : super(key: key);

  @override
  _InternshipPostPageState createState() => _InternshipPostPageState();
}

class _InternshipPostPageState extends State<InternshipPostPage> {
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
  final _durationController = TextEditingController();
  final _stipendController = TextEditingController();
  final _applicationLinkController = TextEditingController();
  final _contactEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Check if we're editing an existing internship
    if (widget.internshipData != null) {
      _isEditing = true;
      _titleController.text = widget.internshipData!['title'] ?? '';
      _companyController.text = widget.internshipData!['company'] ?? '';
      _locationController.text = widget.internshipData!['location'] ?? '';
      _descriptionController.text = widget.internshipData!['description'] ?? '';
      _requirementsController.text =
          widget.internshipData!['requirements'] ?? '';
      _durationController.text = widget.internshipData!['duration'] ?? '';
      _stipendController.text = widget.internshipData!['stipend'] ?? '';
      _applicationLinkController.text =
          widget.internshipData!['applicationLink'] ?? '';
      _contactEmailController.text =
          widget.internshipData!['contactEmail'] ?? '';

      // Parse the expiry date if it exists
      if (widget.internshipData!['expiresAt'] != null) {
        try {
          _expiryDate = DateTime.parse(widget.internshipData!['expiresAt']);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    } else {
      // Default company and email for new internship posts
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
    _durationController.dispose();
    _stipendController.dispose();
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

  Future<void> _submitInternship() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final url = _isEditing
            ? Uri.parse(
                'http://localhost:3000/api/internships/${widget.internshipData!['_id']}')
            : Uri.parse('http://localhost:3000/api/internships');

        final internshipData = {
          'title': _titleController.text,
          'company': _companyController.text,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'requirements': _requirementsController.text,
          'duration': _durationController.text,
          'stipend': _stipendController.text,
          'applicationLink': _applicationLinkController.text,
          'contactEmail': _contactEmailController.text,
          'postedBy': {
            'name': widget.alumniData['name'],
            'alumniId': widget.alumniData['_id'],
          },
        };

        if (_expiryDate != null) {
          internshipData['expiresAt'] = _expiryDate!.toIso8601String();
        }

        final response = _isEditing
            ? await http.put(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(internshipData),
              )
            : await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(internshipData),
              );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(_isEditing
                    ? 'Internship updated successfully'
                    : 'Internship posted successfully')),
          );
          Navigator.pop(context, true); // Return success
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception(
              errorData['message'] ?? 'Failed to submit internship');
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
        title:
            Text(_isEditing ? 'Edit Internship Posting' : 'Post an Internship'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Internship Details' : 'Internship Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Internship Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Internship Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.briefcaseOutline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an internship title';
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
                  labelText: 'Internship Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.text),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an internship description';
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

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration *',
                  hintText: 'e.g., 2 months, 6 months',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(MdiIcons.clock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please specify the internship duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Stipend
              TextFormField(
                controller: _stipendController,
                decoration: const InputDecoration(
                  labelText: 'Stipend',
                  hintText: 'e.g., ₹10,000 per month',
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
                title: const Text('Internship Listing Expiry Date'),
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
                        onPressed: _submitInternship,
                        icon: Icon(
                            _isEditing ? MdiIcons.contentSave : MdiIcons.send),
                        label: Text(_isEditing
                            ? 'Update Internship'
                            : 'Post Internship'),
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
