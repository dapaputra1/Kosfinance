import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kos_finance_app/models/user_model.dart';
import 'package:kos_finance_app/models/transaction_model.dart';
import 'package:kos_finance_app/models/category_model.dart';

class ApiService {
  static String baseUrl = 'http://10.0.2.2:3000/api'; // For Android emulator

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('custom_base_url');
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', url);
  }

  // Auth endpoints
  static Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to login');
    }
  }

  static Future<User> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to register');
    }
  }

  static Future<User> updateProfile({
    required String name,
    String? password,
    required String token,
  }) async {
    final Map<String, dynamic> body = {'name': name};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson({
        ...data,
        'token': token,
      });
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update profile');
    }
  }

  // Transaction endpoints
  static Future<List<Transaction>> getTransactions(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  static Future<Transaction> addTransaction(Transaction transaction, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(transaction.toJson()),
    );

    if (response.statusCode == 201) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add transaction');
    }
  }

  static Future<Transaction> updateTransaction(int id, Transaction transaction, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(transaction.toJson()),
    );

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update transaction');
    }
  }

  static Future<void> deleteTransaction(int id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction');
    }
  }

  // Category endpoints
  static Future<List<Category>> getCategories(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboardData(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard data');
    }
  }
}
