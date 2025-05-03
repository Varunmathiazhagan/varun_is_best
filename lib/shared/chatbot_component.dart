import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/chat_utils.dart';

// Chatbot-related variables and methods
class ChatbotComponent {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;
  bool _isDeepMindMode = false;

  // Predefined questions and answers
  static final List<Map<String, String>> _predefinedQA = [
    // Academic and Profile
    {
      'question': 'How do I find a mentor?',
      'answer':
          'To find a mentor, navigate to the "Mentorship" section from the main menu. There you can browse available mentors based on industry, expertise, or location. You can send a mentor request after reviewing their profile.'
    },
    {
      'question': 'Where can I see job postings?',
      'answer':
          'Job postings can be found in the "Career" tab. You can filter jobs by industry, location, and experience level. Alumni can also post job opportunities for fellow graduates.'
    },
    {
      'question': 'How to update my profile?',
      'answer':
          'To update your profile, go to the "Profile" section and click on "Edit Profile". You can update your personal information, work experience, education details, and upload a new profile picture.'
    },
    {
      'question': 'How to connect with other alumni?',
      'answer':
          'You can connect with other alumni through the "Network" section. Search for alumni by name, graduation year, or industry. You can also join alumni groups based on shared interests or graduation years.'
    },

    // General greetings
    {
      'question': 'hi',
      'answer': 'Hello! How can I assist you today with AlumniConnect?'
    },
    {
      'question': 'hello',
      'answer': 'Hi there! Welcome to AlumniConnect. How can I help you?'
    },
    {
      'question': 'hey',
      'answer':
          'Hey! I\'m here to help with any questions about alumni connections, job opportunities, or events.'
    },

    // Events and Activities
    {
      'question': 'How do I register for alumni events?',
      'answer':
          'To register for alumni events, navigate to the "Events" section in the More menu. Browse upcoming events, click on any event you\'re interested in, and press the "Register" button. You\'ll receive a confirmation email after successful registration.'
    },
    {
      'question': 'Are there any upcoming alumni meetups?',
      'answer':
          'Yes! You can find all upcoming alumni meetups in the "Events" section. The next major event is Alumni Connect 2023 on October 15, 2023, at the Main Auditorium. There\'s also a virtual Career Fair scheduled for November 10.'
    },

    // Career and Professional Development
    {
      'question': 'How can alumni help with my career?',
      'answer':
          'Alumni can support your career in many ways: mentorship, job referrals, internship opportunities, and professional advice. Use the "Connect" section to find alumni in your field of interest and reach out to them directly or through our mentorship program.'
    },
    {
      'question': 'Are there any internship opportunities?',
      'answer':
          'Yes, internship opportunities are posted in the "Jobs & Internships" section under the More menu. Alumni regularly post internship opportunities for current students. You can filter internships by department, duration, and whether they are paid or unpaid.'
    },
    {
      'question': 'How do I apply for jobs through the platform?',
      'answer':
          'To apply for jobs, go to "Jobs & Internships" in the More menu, browse available positions, and click "Apply" on jobs you\'re interested in. You\'ll need to have your resume uploaded to your profile. Some positions may redirect you to the employer\'s website to complete the application.'
    },

    // Mentoring and Guidance
    {
      'question': 'What is the mentorship program?',
      'answer':
          'The mentorship program connects current students with alumni mentors in their field of interest. Mentors provide career guidance, industry insights, and professional development advice. Applications for the program are currently open until September 30, 2023.'
    },
    {
      'question': 'How long does the mentoring program last?',
      'answer':
          'The formal mentoring program lasts for 6 months, but many mentor-mentee relationships continue informally beyond this period. During the program, you\'ll have structured check-ins and goals to achieve with your mentor.'
    },

    // App Navigation and Features
    {
      'question': 'How do I use the discussion forum?',
      'answer':
          'The discussion forum can be accessed from the bottom navigation bar. You can browse existing discussions by topic, create new discussion threads, and contribute to ongoing conversations. Be respectful of community guidelines when posting.'
    },
    {
      'question': 'What information can I see about alumni?',
      'answer':
          'You can view alumni profiles that include their name, graduation year, current company, department of study, contact information (if they\'ve made it public), and social media links. Some alumni also share their professional achievements and areas of expertise.'
    },
    {
      'question': 'How do I message an alumnus?',
      'answer':
          'To message an alumnus, go to their profile through the "Connect" section, and click on the "Message" button. Your message will be sent to their email address. Some alumni also provide direct contact methods like LinkedIn profiles.'
    },

    // About the Platform
    {
      'question': 'What is AlumniConnect?',
      'answer':
          'AlumniConnect is a platform that bridges current students and alumni. It offers networking opportunities, mentorship programs, job postings, discussion forums, and events to strengthen the alumni community and provide value to both current students and graduates.'
    },
    {
      'question': 'Who can join AlumniConnect?',
      'answer':
          'AlumniConnect is available to all current students, graduates, and faculty members of the institution. Students get access automatically with their academic credentials, while alumni can sign up using their graduation details for verification.'
    },

    // Seeking Help
    {
      'question': 'How can I report an issue?',
      'answer':
          'To report an issue with the platform, go to the More section and click on "Help & Support." From there, you can submit a detailed description of the problem you\'re experiencing. Our support team will get back to you within 48 hours.'
    },
    {
      'question': 'I forgot my password',
      'answer':
          'If you\'ve forgotten your password, click on "Forgot Password" on the login screen. Enter your registered email address, and we\'ll send you a link to reset your password. Check your spam folder if you don\'t receive the email within a few minutes.'
    },

    // General Help
    {
      'question': 'thanks',
      'answer':
          'You\'re welcome! Feel free to ask if you have any other questions about AlumniConnect.'
    },
    {
      'question': 'thank you',
      'answer':
          'You\'re very welcome! Is there anything else I can help you with today?'
    },
    {
      'question': 'bye',
      'answer':
          'Goodbye! Feel free to return if you have more questions about AlumniConnect.'
    }
  ];

  void dispose() {
    _chatController.dispose();
  }

  Future<void> _sendChatMessage(String message, Function setState) async {
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'message': message});
      _isChatLoading = true;
    });

    // Check if the message matches any predefined questions
    final predefinedAnswer = _getPredefinedAnswer(message);
    if (predefinedAnswer != null && !_isDeepMindMode) {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate processing
      setState(() {
        _chatMessages.add({'role': 'bot', 'message': predefinedAnswer});
        _isChatLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final reply = responseData['reply'];
        setState(() {
          _chatMessages.add({'role': 'bot', 'message': reply});
        });
      } else {
        throw Exception('Failed to fetch response');
      }
    } catch (e) {
      setState(() {
        _chatMessages.add(
            {'role': 'bot', 'message': 'Error: Unable to fetch response.'});
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  String? _getPredefinedAnswer(String question) {
    // First try exact match (case-insensitive)
    question = question.trim().toLowerCase();

    // Check for exact matches
    for (var qa in _predefinedQA) {
      if (qa['question']!.toLowerCase() == question) {
        return qa['answer'];
      }
    }

    // If no exact match, try fuzzy matching
    return ChatUtils.findBestMatchingAnswer(_predefinedQA, question);
  }

  // Display suggested questions based on current input
  List<String> _getSuggestedQuestions(String input) {
    if (input.isEmpty) {
      return []; // No suggestions for empty input
    }

    input = input.toLowerCase().trim();
    List<String> suggestions = [];

    for (var qa in _predefinedQA) {
      String question = qa['question']!;
      // Add if the question contains the input or input contains part of the question
      if (question.toLowerCase().contains(input) ||
          (input.length > 3 &&
              ChatUtils.calculateSimilarity(question.toLowerCase(), input) >
                  0.4)) {
        if (!suggestions.contains(question) && suggestions.length < 5) {
          suggestions.add(question);
        }
      }
    }

    return suggestions;
  }

  void openChatBotDialog(BuildContext context) {
    // Reset to default mode when opening dialog
    _isDeepMindMode = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Suggestions based on current input
            List<String> suggestions =
                _getSuggestedQuestions(_chatController.text);

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AlumniConnect Assistant',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Switch(
                    value: _isDeepMindMode,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      setState(() {
                        _isDeepMindMode = value;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'DeepMind Mode: ',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _isDeepMindMode ? 'ON' : 'OFF',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: _isDeepMindMode
                                ? Colors.deepPurple
                                : Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _chatMessages.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Clear chat',
                        ),
                      ],
                    ),
                    if (!_isDeepMindMode)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        height: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Frequently Asked Questions:',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildFAQCategory(
                                      'General',
                                      [
                                        'What is AlumniConnect?',
                                        'How to update my profile?',
                                        'How do I use the discussion forum?'
                                      ],
                                      setState),
                                  const SizedBox(width: 10),
                                  _buildFAQCategory(
                                      'Career',
                                      [
                                        'Where can I see job postings?',
                                        'Are there any internship opportunities?',
                                        'How can alumni help with my career?'
                                      ],
                                      setState),
                                  const SizedBox(width: 10),
                                  _buildFAQCategory(
                                      'Networking',
                                      [
                                        'How do I find a mentor?',
                                        'How to connect with other alumni?',
                                        'How do I message an alumnus?'
                                      ],
                                      setState),
                                  const SizedBox(width: 10),
                                  _buildFAQCategory(
                                      'Events',
                                      [
                                        'How do I register for alumni events?',
                                        'Are there any upcoming alumni meetups?',
                                        'What is the mentorship program?'
                                      ],
                                      setState),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _chatMessages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 50,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ask me anything about AlumniConnect!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'I can help you navigate the platform, find mentors, \ndiscover job opportunities, and more.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _chatMessages.length,
                                itemBuilder: (context, index) {
                                  final chat = _chatMessages[index];
                                  return Align(
                                    alignment: chat['role'] == 'user'
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.6,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: chat['role'] == 'user'
                                            ? Colors.blue.shade100
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        chat['message']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (_isChatLoading)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text("Thinking..."),
                          ],
                        ),
                      ),
                    if (suggestions.isNotEmpty &&
                        _chatController.text.isNotEmpty)
                      Container(
                        height: 40,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () {
                                  _chatController.text = suggestions[index];
                                  // Force update of suggestions
                                  setState(() {});
                                },
                                child: Text(
                                  suggestions[index],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _chatController,
                        onChanged: (_) =>
                            setState(() {}), // Update for suggestions
                        decoration: InputDecoration(
                          hintText: _isDeepMindMode
                              ? 'Ask anything with DeepMind...'
                              : 'Type your question here...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.blue),
                            onPressed: () {
                              if (_chatController.text.trim().isNotEmpty) {
                                _sendChatMessage(
                                    _chatController.text, setState);
                                _chatController.clear();
                              }
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _sendChatMessage(value, setState);
                            _chatController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFAQCategory(
      String category, List<String> questions, Function setState) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
              fontSize: 12,
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    _sendChatMessage(questions[index], setState);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      questions[index],
                      style: GoogleFonts.poppins(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
