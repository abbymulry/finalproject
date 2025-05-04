import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// manages authentication state throughout the app
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String _error = '';

  // getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String get error => _error;

  // check if user is logged in
  Future<void> checkCurrentUser() async {
    final user = _authService.currentUser;
    print('Checking current user: ${user?.uid}');
    if (user != null) {
      try {
        _user = await _authService.getUserProfile(user.uid);
        print('Got user profile: ${_user?.email}');
      } catch (e) {
        print('Error getting user profile: $e');
        // Create a basic user model if profile retrieval fails
        _user = UserModel(
          uid: user.uid,
          email: user.email ?? '',
        );
        print('Created basic user model: ${_user?.email}');
      }
      notifyListeners();
    } else {
      print('No current user found');
    }
  }

  // sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // register with email and password
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _user = await _authService.registerWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  
}