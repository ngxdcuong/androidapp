import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2/api/index.php";

  static Future<List<dynamic>> getExpenses() async {
    final res = await http.get(Uri.parse(baseUrl));
    return jsonDecode(res.body);
  }

  static Future<void> addExpense(Map data) async {
    await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  static Future<void> deleteExpense(int id) async {
    await http.delete(
      Uri.parse("$baseUrl?id=$id"),
    );
  }

  static Future<void> clearAll() async {
    await http.delete(
      Uri.parse("$baseUrl?all=true"),
    );
  }
}