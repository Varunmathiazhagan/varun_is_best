import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../services/discussion_service.dart';
import '../services/notification_service.dart';
import '../shared/notification_icon.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class DiscussionForumSharedPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String userType; // 'student' or 'alumni'

  const DiscussionForumSharedPage(
      {Key? key, required this.userData, required this.userType})
      : super(key: key);

  @override
  State<DiscussionForumSharedPage> createState() =>
      _DiscussionForumSharedPageState();
}

class _DiscussionForumSharedPageState extends State<DiscussionForumSharedPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final DiscussionService _discussionService = DiscussionService();
  late TabController _tabController;
  String _selectedTag = "All";
  bool _isLoading = true;
  List<dynamic> _questions = [];
  List<dynamic> _filteredQuestions = [];
  String _errorMessage = "";
  List<String> _availableTags = ["All"];
  List<dynamic> _articles = [];
  bool _isLoadingFeeds = true;
  String? _feedError;
  int _feedsPerPage = 10;
  int _currentPage = 0;

  // Add variables for notifications
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchQuestions();
    _fetchNewsFeeds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      final tag = _selectedTag != "All" ? _selectedTag : null;
      final search =
          _searchController.text.isEmpty ? null : _searchController.text;

      final questions = await _discussionService.getQuestions(
        tag: tag,
        search: search,
      );

      // Extract all unique tags from questions
      final Set<String> tagSet = {'All'};
      for (var question in questions) {
        final tags = question['tags'] as List<dynamic>;
        for (var tag in tags) {
          tagSet.add(tag.toString());
        }
      }

      setState(() {
        _questions = questions;
        _filteredQuestions = questions;
        _availableTags = tagSet.toList()..sort((a, b) => a.compareTo(b));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showNewQuestionDialog() async {
    // Remove role check - allow both students and alumni to post questions

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagController = TextEditingController();
    List<String> tags = [];
    XFile? selectedImage;
    Uint8List? imageBytes;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Post a New Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Question Details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: InputDecoration(
                          labelText: 'Add Tag (e.g., #career)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (tagController.text.isNotEmpty) {
                          String tag = tagController.text;
                          if (!tag.startsWith('#')) {
                            tag = '#$tag';
                          }
                          setState(() {
                            tags.add(tag);
                          });
                          tagController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tag added: $tag')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: Icon(Icons.close),
                            onDeleted: () {
                              setState(() {
                                tags.remove(tag);
                              });
                            },
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),
                // Add image upload button
                ElevatedButton.icon(
                  icon: Icon(Icons.photo),
                  label: Text('Upload Photo'),
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker
                          .pickImage(
                        source: ImageSource.gallery,
                      )
                          .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error accessing image picker: $error')),
                        );
                        return null;
                      });

                      if (image != null) {
                        // Read image bytes
                        final bytes = await image.readAsBytes();
                        setState(() {
                          selectedImage = image;
                          imageBytes = bytes;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Photo selected')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to select image: $e')),
                      );
                    }
                  },
                ),
                if (selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Photo selected: ${selectedImage?.name}',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.clear, size: 16),
                          onPressed: () {
                            setState(() {
                              selectedImage = null;
                              imageBytes = null;
                            });
                          },
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Title and question details are required')),
                  );
                  return;
                }

                try {
                  await _discussionService.postQuestion(
                    {
                      'title': titleController.text,
                      'content': contentController.text,
                      'author': widget.userData?['name'] ?? 'Anonymous',
                      'authorId': widget.userData?['username'] ?? 'anonymous',
                      'authorType': widget.userType,
                      'tags': tags.isEmpty ? ['#general'] : tags,
                    },
                    imageBytes: imageBytes,
                    imageName: selectedImage?.name,
                  );

                  Navigator.pop(context, true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error posting question: $e')),
                  );
                }
              },
              child: Text('Post Question'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // Refresh questions list
      await _fetchQuestions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question posted successfully!')),
      );
    }
  }

  Future<void> _showAnswerDialog(String questionId) async {
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Post Your Answer'),
        content: SingleChildScrollView(
          child: TextField(
            controller: contentController,
            decoration: InputDecoration(
              labelText: 'Your Answer',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Answer content is required')),
                );
                return;
              }

              try {
                await _discussionService.postAnswer(questionId, {
                  'content': contentController.text,
                  'author': widget.userData?['name'] ?? 'Anonymous',
                  'authorId': widget.userData?['username'] ?? 'anonymous',
                  'authorType': widget.userType,
                });

                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error posting answer: $e')),
                );
              }
            },
            child: Text('Post Answer'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Refresh questions list
      await _fetchQuestions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Answer posted successfully!')),
      );
    }
  }

  Future<void> _addComment(String questionId) async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment cannot be empty')),
      );
      return;
    }

    try {
      await _discussionService.addComment(
        questionId,
        {
          'content': _commentController.text,
          'author': widget.userData?['name'] ?? 'Anonymous',
          'authorId': widget.userData?['username'] ?? 'anonymous',
          'authorType': widget.userType,
        },
      );

      // Clear the comment field and refresh questions
      _commentController.clear();
      await _fetchQuestions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  // Update to include sender info when liking
  Future<void> _likeQuestion(String questionId) async {
    try {
      final result = await _discussionService.likeQuestion(
        questionId,
        widget.userData?['username'] ?? 'anonymous',
        widget.userData?['name'] ?? 'Anonymous',
        widget.userType,
      );

      await _fetchQuestions(); // Refresh to get updated like count

      final liked = result['liked'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(liked ? 'Question liked!' : 'Like removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking question: $e')),
      );
    }
  }

  Future<void> _fetchNewsFeeds() async {
    try {
      setState(() {
        _isLoadingFeeds = true;
        _feedError = null;
      });

      const apiKey =
          '8b6c001fd05c4f099e617d5dffb8deae'; // You should store this in a secure place
      final today = DateTime.now();
      final lastWeek = today.subtract(const Duration(days: 7));
      final formattedDate = lastWeek.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse(
            'https://newsapi.org/v2/everything?q=placements+OR+studies+OR+education&from=$formattedDate&apiKey=$apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch news');
      }

      final data = jsonDecode(response.body);
      setState(() {
        _articles = data['articles'];
        _isLoadingFeeds = false;
      });
    } catch (e) {
      setState(() {
        _feedError = 'Failed to load news articles. Please try again later.';
        _isLoadingFeeds = false;
      });
    }
  }

  void _loadMoreFeeds() {
    setState(() {
      _currentPage++;
    });
  }

  Future<void> _refreshFeeds() async {
    setState(() {
      _currentPage = 0;
    });
    await _fetchNewsFeeds();
  }

  // Add method to handle notifications update
  void _handleNotificationsUpdate(List<dynamic> notifications) {
    setState(() {
      _notifications = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion Forum'),
        actions: [
          // Add notification icon
          if (widget.userData != null && widget.userData?['username'] != null)
            NotificationIcon(
              userId: widget.userData!['username'],
              onNotificationsUpdated: _handleNotificationsUpdate,
            ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              if (widget.userType == 'student') {
                Navigator.pushNamed(context, '/student_profile',
                    arguments: widget.userData);
              } else {
                Navigator.pushNamed(context, '/alumni_profile',
                    arguments: widget.userData);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Discussions', icon: Icon(MdiIcons.forum)),
            Tab(text: 'Education Feed', icon: Icon(MdiIcons.newspaper)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Discussions Tab
          _buildDiscussionsTab(),

          // Feeds Tab
          _buildFeedsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showNewQuestionDialog,
              child: Icon(Icons.add),
              tooltip: 'Post a Question',
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _buildDiscussionsTab() {
    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _fetchQuestions();
                    },
                  ),
                ),
                onSubmitted: (_) => _fetchQuestions(),
              ),
              SizedBox(height: 8),
              // Hashtag filter section - enhanced with more visibility
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Tags:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _availableTags
                            .map((tag) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Text(tag),
                                    selected: _selectedTag == tag,
                                    selectedColor: Colors.blue.shade200,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedTag = selected ? tag : "All";
                                      });
                                      _fetchQuestions();
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Updated role indicator - now both can post questions
        Container(
          color: widget.userType == 'student'
              ? Colors.blue.shade50
              : Colors.amber.shade50,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Icon(
                widget.userType == 'student'
                    ? MdiIcons.account
                    : MdiIcons.accountStar,
                color:
                    widget.userType == 'student' ? Colors.blue : Colors.amber,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.userType == 'student'
                      ? 'Logged in as Student: You can post questions and view answers'
                      : 'Logged in as Alumni: You can post questions and provide answers',
                  style: TextStyle(
                    color: widget.userType == 'student'
                        ? Colors.blue.shade900
                        : Colors.amber.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Questions list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : _filteredQuestions.isEmpty
                      ? Center(child: Text('No questions found'))
                      : ListView.builder(
                          itemCount: _filteredQuestions.length,
                          itemBuilder: (context, index) {
                            final question = _filteredQuestions[index];
                            final answers =
                                question['answers'] as List<dynamic>;
                            final comments = question['comments'] != null
                                ? question['comments'] as List<dynamic>
                                : [];
                            final questionId = question['_id'];
                            final String? photoUrl = question['photo'];
                            final likes = question['likes'] ?? 0;
                            final likedBy =
                                question['likedBy'] as List<dynamic>? ?? [];
                            final isLiked = likedBy.contains(
                                widget.userData?['username'] ?? 'anonymous');

                            return Card(
                              margin: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Question header
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          question['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Asked by ${question['author']} (${question['authorType']}) • ${_formatDate(question['timestamp'])}',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        SizedBox(height: 8),
                                        // Display tags
                                        Wrap(
                                          spacing: 4,
                                          children: (question['tags']
                                                  as List<dynamic>)
                                              .map((tag) => Chip(
                                                    label: Text(
                                                      tag.toString(),
                                                      style: TextStyle(
                                                          fontSize: 10),
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Question content
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: Text(question['content']),
                                  ),

                                  // Display photo if available
                                  if (photoUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          'http://localhost:3000${photoUrl}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 100,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child:
                                                    Text('Image not available'),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                  // Like button and comment button
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        // Like button
                                        InkWell(
                                          onTap: () =>
                                              _likeQuestion(questionId),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isLiked
                                                      ? Icons.thumb_up
                                                      : Icons.thumb_up_outlined,
                                                  size: 18,
                                                  color: isLiked
                                                      ? Colors.blue
                                                      : Colors.grey,
                                                ),
                                                SizedBox(width: 4),
                                                Text('$likes'),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        // Comments count
                                        Row(
                                          children: [
                                            Icon(Icons.comment_outlined,
                                                size: 18, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text('${comments.length}'),
                                          ],
                                        ),
                                        SizedBox(width: 16),
                                        // Answers count
                                        Row(
                                          children: [
                                            Icon(Icons.question_answer_outlined,
                                                size: 18, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text('${answers.length}'),
                                          ],
                                        ),
                                        Spacer(),
                                        // View details button
                                        TextButton.icon(
                                          icon:
                                              Icon(Icons.expand_more, size: 16),
                                          label: Text('View Details'),
                                          onPressed: () {
                                            // Show the full question, comments and answers in a bottom sheet
                                            _showQuestionDetails(question);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Comments section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: comments.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Divider(),
                                              Text(
                                                'Comments',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14),
                                              ),
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                itemCount: comments.length > 2
                                                    ? 2
                                                    : comments
                                                        .length, // Show only 2 comments in preview
                                                itemBuilder: (context, idx) {
                                                  final comment = comments[idx];
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 4.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 12,
                                                          child: Text(
                                                            comment['author'][0]
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                                fontSize: 10),
                                                          ),
                                                        ),
                                                        SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              RichText(
                                                                text: TextSpan(
                                                                  style: DefaultTextStyle.of(
                                                                          context)
                                                                      .style,
                                                                  children: [
                                                                    TextSpan(
                                                                      text:
                                                                          '${comment['author']} ',
                                                                      style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                    TextSpan(
                                                                        text: comment[
                                                                            'content']),
                                                                  ],
                                                                ),
                                                              ),
                                                              Text(
                                                                _formatDate(comment[
                                                                    'timestamp']),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (comments.length > 2)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4.0),
                                                  child: Text(
                                                    'View all ${comments.length} comments',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Container(),
                                  ),

                                  // Add comment field
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          child: Text(
                                            (widget.userData?['name'] ?? 'A')[0]
                                                .toUpperCase(),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _commentController,
                                            decoration: InputDecoration(
                                              hintText: 'Write a comment...',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                            ),
                                            minLines: 1,
                                            maxLines: 3,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.send),
                                          onPressed: () =>
                                              _addComment(questionId),
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
    );
  }

  Widget _buildFeedsTab() {
    // Calculate the start and end indices for pagination
    final int startIndex = _currentPage * _feedsPerPage;
    final int endIndex = startIndex + _feedsPerPage;

    // Get the current page of articles
    final List<dynamic> currentArticles =
        _isLoadingFeeds || _feedError != null || _articles.isEmpty
            ? []
            : _articles.length > endIndex
                ? _articles.sublist(startIndex, endIndex)
                : _articles.sublist(startIndex, _articles.length);

    return _isLoadingFeeds
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blue[600],
                  strokeWidth: 4,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading educational news...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          )
        : _feedError != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      _feedError!,
                      style: TextStyle(fontSize: 18, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      onPressed: _refreshFeeds,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshFeeds,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Latest Education News',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    Expanded(
                      child: currentArticles.isEmpty
                          ? Center(child: Text('No articles found'))
                          : ListView.builder(
                              itemCount: currentArticles.length +
                                  1, // +1 for load more button
                              itemBuilder: (context, index) {
                                // Show load more button at the end
                                if (index == currentArticles.length) {
                                  // Only show if there are more articles
                                  if ((startIndex + _feedsPerPage) <
                                      _articles.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed: _loadMoreFeeds,
                                          child: Text('Load More'),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: Center(
                                        child: Text(
                                          'No more articles',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }
                                }

                                // Display article
                                final article = currentArticles[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (article['urlToImage'] != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(12)),
                                          child: CachedNetworkImage(
                                            imageUrl: article['urlToImage'],
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.broken_image,
                                                  size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article['title'] ?? 'No title',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              article['description'] ??
                                                  'No description available',
                                              style: TextStyle(fontSize: 14),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Source: ${article['source']?['name'] ?? 'Unknown'}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    // Open article in web view or external browser
                                                    // This could be implemented later
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'Article link clicked')),
                                                    );
                                                  },
                                                  child: Text('Read More'),
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

  void _showQuestionDetails(Map<String, dynamic> question) {
    final questionId = question['_id'];
    final answers = question['answers'] as List<dynamic>;
    final comments = question['comments'] != null
        ? question['comments'] as List<dynamic>
        : [];
    final String? photoUrl = question['photo'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question title and author info
                    Text(
                      question['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Asked by ${question['author']} (${question['authorType']}) • ${_formatDate(question['timestamp'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 16),

                    // Question content
                    Text(question['content']),
                    SizedBox(height: 16),

                    // Display photo if available
                    if (photoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          'http://localhost:3000${photoUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: Text('Image not available'),
                              ),
                            );
                          },
                        ),
                      ),

                    Divider(height: 32),

                    // Comments section
                    if (comments.isNotEmpty) ...[
                      Text(
                        'Comments (${comments.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, idx) {
                          final comment = comments[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(comment['author'][0].toUpperCase()),
                            ),
                            title: Text(comment['author']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment['content']),
                                Text(
                                  _formatDate(comment['timestamp']),
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                            dense: true,
                          );
                        },
                      ),
                      Divider(height: 32),
                    ],

                    // Add comment field
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          child: Text(
                            (widget.userData?['name'] ?? 'A')[0].toUpperCase(),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 3,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            _addComment(questionId);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),

                    Divider(height: 32),

                    // Answers section
                    if (answers.isNotEmpty) ...[
                      Text(
                        'Answers (${answers.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: answers.length,
                        itemBuilder: (context, idx) {
                          final answer = answers[idx];
                          final answerId = answer['_id'];
                          final userId =
                              widget.userData?['username'] ?? 'anonymous';
                          final likedBy =
                              answer['likedBy'] as List<dynamic>? ?? [];
                          final isLiked = likedBy.contains(userId);

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            color: answer['authorType'] == 'alumni'
                                ? Colors.amber.shade50
                                : Colors.grey.shade50,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ...existing answer card content...
                                  Row(
                                    children: [
                                      Icon(
                                        answer['authorType'] == 'alumni'
                                            ? MdiIcons.accountStar
                                            : MdiIcons.account,
                                        size: 18,
                                        color: answer['authorType'] == 'alumni'
                                            ? Colors.amber.shade800
                                            : Colors.grey,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '${answer['author']} (${answer['authorType']})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              answer['authorType'] == 'alumni'
                                                  ? Colors.amber.shade800
                                                  : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(answer['content']),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(answer['timestamp']),
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          Text('${answer['likes']}'),
                                          IconButton(
                                            icon: Icon(
                                              isLiked
                                                  ? Icons.thumb_up
                                                  : Icons.thumb_up_outlined,
                                              size: 18,
                                              color: isLiked
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            onPressed: () {
                                              _likeAnswer(questionId, answerId);
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Answer question button
                    if (widget.userType == 'alumni')
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.reply),
                          label: Text('Answer This Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _showAnswerDialog(questionId);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _likeAnswer(String questionId, String answerId) async {
    try {
      final result = await _discussionService.likeAnswer(
        questionId,
        answerId,
        widget.userData?['username'] ?? 'anonymous',
      );

      await _fetchQuestions(); // Refresh to get updated like count

      final liked = result['liked'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(liked ? 'Answer liked!' : 'Like removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking answer: $e')),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      // Handle the case where timestamp might be a different format
      return 'Invalid date';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
