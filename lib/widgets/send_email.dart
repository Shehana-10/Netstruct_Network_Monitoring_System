import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  final String apiKey =
      "re_YJf561gY_Az3WijHm6z4RxEnkhcZhzHDo"; // Replace with your actual Resend API key

  Future<void> sendEmail({
    required String recipient,
    required String subject,
    required String message,
  }) async {
    final url = Uri.parse('https://api.resend.com/emails'); // Resend API URL

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'from': 'onboarding@resend.dev', // Replace with your sender email
      'to': [recipient],
      'subject': subject,
      'html': '<p>$message</p>',
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      print("Email sent successfully");
    } else {
      print("Failed to send email: ${response.body}");
    }
  }
}
