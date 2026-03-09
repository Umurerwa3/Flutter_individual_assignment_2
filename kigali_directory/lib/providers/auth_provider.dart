import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

enum AuthStatus { idle, loading, error }

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  User? _user;
  UserProfile? _profile;
  AuthStatus _status = AuthStatus.loading;
  String _errorMsg = '';

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _status == AuthStatus.loading;
  String get errorMsg => _errorMsg;

  AuthProvider() {
    _service.userStream.listen((u) async {
      _user = u;
      try {
        if (u != null) {
          _profile = await _service.getUserProfile(u.uid);
        } else {
          _profile = null;
        }
        _errorMsg = '';
      } catch (e) {
        _profile = null;
        _errorMsg = e.toString();
      }
      _status = AuthStatus.idle;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String pass, String name) async {
    _status = AuthStatus.loading;
    _errorMsg = '';
    notifyListeners();
    try {
      await _service.signUp(email, pass, name);
    } on FirebaseAuthException catch (e) {
      _errorMsg = e.message ?? 'Sign up failed';
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String pass) async {
    _status = AuthStatus.loading;
    _errorMsg = '';
    notifyListeners();
    try {
      await _service.signIn(email, pass);
    } on FirebaseAuthException catch (e) {
      _errorMsg = e.message ?? 'Sign in failed';
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  Future<void> resendVerification() => _service.resendVerification();

  Future<void> reloadUser() async {
    await _service.reloadUser();
    _user = _service.currentUser;
    notifyListeners();
  }
}