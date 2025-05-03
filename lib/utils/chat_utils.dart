class ChatUtils {
  /// Calculate similarity between two strings using a simple approach
  static double calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Convert to lowercase for case-insensitive comparison
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    // Split into words
    final words1 = s1.split(RegExp(r'\s+'));
    final words2 = s2.split(RegExp(r'\s+'));

    // Count matching words
    int matches = 0;
    for (final word1 in words1) {
      if (word1.length <= 2) continue; // Skip very short words
      for (final word2 in words2) {
        if (word1 == word2 || (word1.length > 3 && word2.contains(word1))) {
          matches++;
          break;
        }
      }
    }

    // Calculate similarity score
    final maxWords =
        words1.length > words2.length ? words1.length : words2.length;
    return matches / maxWords;
  }

  /// Find the best matching question and return its answer
  static String? findBestMatchingAnswer(
      List<Map<String, String>> qaList, String query) {
    double highestScore = 0.0;
    String? bestAnswer;

    for (final qa in qaList) {
      final question = qa['question']!.toLowerCase();
      final similarity = calculateSimilarity(question, query);

      // Check if this is a better match
      if (similarity > highestScore && similarity > 0.5) {
        highestScore = similarity;
        bestAnswer = qa['answer'];
      }

      // Check for key phrase matches
      if (query.contains(question) && question.length > 3) {
        if (question.length / query.length > 0.5) {
          return qa['answer'];
        }
      }
    }

    return bestAnswer;
  }
}
