import 'package:flutter/foundation.dart';
import 'login_model.dart';

class LoginController with ChangeNotifier {
  final LoginModel model = LoginModel();
  bool loading = false;
  String? error;

  void setEmail(String e) {
    model.email = e;
    notifyListeners();
  }

  void setPassword(String p) {
    model.password = p;
    notifyListeners();
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email required';
    // final emailRegex = RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$');
    // if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 2) return 'Minimum 2 characters';
    return null;
  }

  Future<bool> login() async {
    error = null;
    loading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    loading = false;

    // Simple demo check
    if (model.email == 'kipl' && model.password == '123') {
      notifyListeners();
      return true;
    } else {
      error = 'Invalid credentials (try kipl@gmail.com / Password)';
      notifyListeners();
      return false;
    }
  }
}
