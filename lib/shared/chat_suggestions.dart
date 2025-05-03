class ChatSuggestions {
  // Common topics users might be interested in
  static final Map<String, List<String>> topicSuggestions = {
    'Career': [
      'How do I find job opportunities?',
      'Can alumni help me with career advice?',
      'Are there resume review services?',
      'How can I prepare for interviews?',
      'Which companies typically hire graduates?'
    ],
    'Mentorship': [
      'How do I find a mentor?',
      'What should I ask my mentor?',
      'How long does mentorship last?',
      'Can I change my mentor?',
      'How do I become a mentor?'
    ],
    'Events': [
      'Are there any upcoming alumni events?',
      'How do I register for events?',
      'Are there virtual networking events?',
      'How can I host an alumni event?',
      'Are there industry-specific meetups?'
    ],
    'Networking': [
      'How to connect with alumni in my field?',
      'Best practices for networking?',
      'How to message alumni professionally?',
      'Are there alumni groups by location?',
      'How to follow up after connecting?'
    ],
    'Platform Help': [
      'How to update my profile?',
      'How to reset my password?',
      'Who can see my contact information?',
      'How to report inappropriate content?',
      'How to change notification settings?'
    ]
  };

  // Contextual follow-up suggestions based on previous interactions
  static Map<String, List<String>> getFollowUpSuggestions(
      String previousQuestion) {
    previousQuestion = previousQuestion.toLowerCase();

    if (previousQuestion.contains('mentor')) {
      return {
        'Mentorship': [
          'How do I schedule meetings with my mentor?',
          'What should I prepare for my first mentor meeting?',
          'How often should I meet with my mentor?',
          'Can my mentor help with job referrals?',
          'What if my mentorship isn\'t working out?'
        ]
      };
    }

    if (previousQuestion.contains('job') ||
        previousQuestion.contains('career') ||
        previousQuestion.contains('employment') ||
        previousQuestion.contains('work')) {
      return {
        'Career Development': [
          'What industries do most alumni work in?',
          'How can I showcase my portfolio?',
          'Are there alumni working at specific companies?',
          'Can I get mock interview practice?',
          'How to negotiate job offers?'
        ]
      };
    }

    if (previousQuestion.contains('event') ||
        previousQuestion.contains('meetup')) {
      return {
        'Events': [
          'What happens at alumni networking events?',
          'Are there costs associated with events?',
          'Can I bring guests to events?',
          'Will there be recruiters at the events?',
          'Are there recordings of past events?'
        ]
      };
    }

    if (previousQuestion.contains('profile') ||
        previousQuestion.contains('update')) {
      return {
        'Profile Management': [
          'What information should I include in my profile?',
          'Who can see my profile information?',
          'How do I add my work experience?',
          'Can I link my social media accounts?',
          'How to upload my resume?'
        ]
      };
    }

    // Default suggestions if no context is matched
    return {
      'Popular Questions': [
        'How do I find a mentor?',
        'Where can I see job postings?',
        'How to update my profile?',
        'Are there any upcoming events?',
        'How to connect with other alumni?'
      ]
    };
  }
}
