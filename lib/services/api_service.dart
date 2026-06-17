import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://voltwise-backend.onrender.com';

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load dashboard data. Status: ${response.statusCode}',
    );
  }

  static Future<int> getCurrentUsage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/energy/current'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['current_usage'] as num).toInt();
    }

    throw Exception(
      'Failed to load current usage. Status: ${response.statusCode}',
    );
  }

  static Future<List<dynamic>> getAppliances() async {
    final response = await http.get(
      Uri.parse('$baseUrl/appliances/'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load appliances. Status: ${response.statusCode}',
    );
  }
}