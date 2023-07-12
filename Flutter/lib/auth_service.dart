import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  String? _token;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }

  bool get isAuthenticated => _token != null;

  Future<void> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse(
          'https://zml72q2u2h.execute-api.eu-north-1.amazonaws.com/signin'),
      body: json.encode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseBody['token']);
      _token = responseBody['token'];
      notifyListeners();
    } else {
      throw Exception('Failed to sign in');
    }
  }

  Future<bool> register(
      String name,
      String email,
      String password,
      String confirmPassword,
      int height,
      int weight,
      int age,
      String gender) async {
    final response = await http.post(
      Uri.parse(
          'https://zml72q2u2h.execute-api.eu-north-1.amazonaws.com/register'),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'height': height,
        'weight': weight,
        'age': age,
        'gender': gender,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    if (_token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.post(
      Uri.parse(
          'https://zml72q2u2h.execute-api.eu-north-1.amazonaws.com/getuserdata'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("################################");
      print(_token);
      print("################################");
      print(response.body);
      await signOut();
      throw Exception('Failed to fetch user data');
    }
  }

  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    notifyListeners();
  }
}
