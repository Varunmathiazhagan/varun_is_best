import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class DiscussionService {
  final String baseUrl = 'http://localhost:3000/api/discussions';

  Future<List<dynamic>> getQuestions({String? tag, String? search}) async {
    try {
      String url = baseUrl;
      if (tag != null || search != null) {
        url += '?';
        if (tag != null) url += 'tag=$tag&';
        if (search != null) url += 'search=$search';
        url = url.endsWith('&') ? url.substring(0, url.length - 1) : url;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  Future<Map<String, dynamic>> postQuestion(Map<String, dynamic> questionData,
      {Uint8List? imageBytes, String? imageName}) async {
    try {
      if (imageBytes != null && imageName != null) {
        // Use multipart request for image upload
        var request =
            http.MultipartRequest('POST', Uri.parse(baseUrl + '/question'));

        // Add text fields
        questionData.forEach((key, value) {
          if (value is List) {
            // Handle tags list
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        });

        // Add image file
        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: imageName,
          contentType: MediaType('image', _getImageMimeType(imageName)),
        );
        request.files.add(multipartFile);

        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to post question: ${response.statusCode}');
        }
      } else {
        // Use regular JSON request if no image
        final response = await http.post(Uri.parse(baseUrl + '/question'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(questionData));

        if (response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to post question: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error posting question: $e');
    }
  }

  // Helper function to determine MIME type from file extension
  String _getImageMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      default:
        return 'jpeg'; // Default to JPEG
    }
  }

  Future<Map<String, dynamic>> postAnswer(
      String questionId, Map<String, dynamic> answerData) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$questionId/answer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(answerData));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to post answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error posting answer: $e');
    }
  }

  Future<Map<String, dynamic>> likeAnswer(
      String questionId, String answerId, String userId) async {
    try {
      final response = await http.post(
          Uri.parse('$baseUrl/$questionId/answer/$answerId/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to like answer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking answer: $e');
    }
  }

  Future<Map<String, dynamic>> likeQuestion(String questionId, String userId,
      String senderName, String senderType) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/$questionId/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'senderName': senderName,
            'senderType': senderType
          }));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to like question: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking question: $e');
    }
  }

  Future<Map<String, dynamic>> addComment(
      String questionId, Map<String, dynamic> commentData) async {
    try {
      final response = await http.post(
          Uri.parse('$baseUrl/$questionId/comment'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(commentData));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }
}
