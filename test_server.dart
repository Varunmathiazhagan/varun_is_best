import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('Testing server connection...');
  
  try {
    // Test basic server connection
    final response = await http.get(Uri.parse('http://localhost:3000/'));
    print('Server response: ${response.statusCode}');
    
    // Test events endpoint
    try {
      final eventsResponse = await http.get(
        Uri.parse('http://localhost:3000/api/test/db'),
      );
      print('Database test response: ${eventsResponse.statusCode}');
      print('Response body: ${eventsResponse.body}');
      
      if (eventsResponse.statusCode == 200) {
        final data = jsonDecode(eventsResponse.body);
        print('Collections: ${data['collections']}');
      }
    } catch (e) {
      print('Error testing events endpoint: $e');
    }
  } catch (e) {
    print('Server connection failed: $e');
    print('Make sure your server is running on localhost:3000');
    print('To start the server, open a command prompt and run:');
    print('cd d:\\mudich\\alumniconnect-backend');
    print('node server.js');
  }
}
