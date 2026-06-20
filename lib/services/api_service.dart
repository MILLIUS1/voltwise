import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://voltwise-backend.onrender.com';

  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load dashboard. Status: ${response.statusCode}');
  }

  static Future<int> getCurrentUsage() async {
    final response = await http.get(
      Uri.parse('$baseUrl/energy/current'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['current_usage'] as num).toInt();
    }

    throw Exception('Failed to load current usage. Status: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAppliances() async {
    final response = await http.get(
      Uri.parse('$baseUrl/appliances/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load appliances. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateAppliancePriority({
    required int applianceId,
    required String priority,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/appliances/$applianceId'),
      headers: headers,
      body: jsonEncode({'priority': priority.toUpperCase()}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update priority. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateApplianceStatus({
    required int applianceId,
    required bool status,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/appliances/$applianceId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update status. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings/latest'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load settings. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> saveSettings({
    required double conservationThreshold,
    required double criticalThreshold,
    required double reserveLevel,
    required bool notificationsEnabled,
    required bool darkModeEnabled,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings/'),
      headers: headers,
      body: jsonEncode({
        'conservation_threshold': conservationThreshold,
        'critical_threshold': criticalThreshold,
        'reserve_level': reserveLevel,
        'notifications_enabled': notificationsEnabled,
        'dark_mode_enabled': darkModeEnabled,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to save settings. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateBattery({
    required double batteryLevel,
    required double batteryVoltage,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/battery/'),
      headers: headers,
      body: jsonEncode({
        'battery_level': batteryLevel,
        'battery_voltage': batteryVoltage,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update battery. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getLatestBattery() async {
    final response = await http.get(
      Uri.parse('$baseUrl/battery/latest'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load battery. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateGrid({
    required bool isAvailable,
    required double voltage,
    required double frequency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/grid/'),
      headers: headers,
      body: jsonEncode({
        'is_available': isAvailable,
        'voltage': voltage,
        'frequency': frequency,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to update grid. Status: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> getLatestGrid() async {
    final response = await http.get(
      Uri.parse('$baseUrl/grid/latest'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load grid. Status: ${response.statusCode}');
  }

  static Future<List<dynamic>> getAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load alerts. Status: ${response.statusCode}');
  }

static Future<Map<String, dynamic>> getReportsSummary() async {
  final response = await http.get(
    Uri.parse('$baseUrl/reports/summary'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception('Failed to load reports summary. Status: ${response.statusCode}');
}

static Future<List<dynamic>> getApplianceBreakdown() async {
  final response = await http.get(
    Uri.parse('$baseUrl/reports/appliance-breakdown'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception('Failed to load appliance breakdown. Status: ${response.statusCode}');
}

static Future<List<dynamic>> getDailyReport() async {
  final response = await http.get(
    Uri.parse('$baseUrl/reports/daily'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  
  throw Exception('Failed to load daily report. Status: ${response.statusCode}');
  
}  
}