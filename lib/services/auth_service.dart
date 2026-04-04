import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  static const _keyUsername = 'auth_username';
  static const _keyPassword = 'auth_password';
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyOnboarded = 'onboarding_complete';

  Future<String?> get currentUser async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_keyLoggedIn) != true) return null;
    return p.getString(_keyUsername);
  }

  Future<bool> get isLoggedIn async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyLoggedIn) ?? false;
  }

  /// Returns null on success, error message on failure.
  Future<String?> register(String username, String password) async {
    if (username.trim().length < 3) return 'Username must be at least 3 characters';
    if (password.length < 6) return 'Password must be at least 6 characters';
    final p = await SharedPreferences.getInstance();
    if (p.getString(_keyUsername) != null) return 'An account already exists on this device';
    await p.setString(_keyUsername, username.trim());
    await p.setString(_keyPassword, password);
    await p.setBool(_keyLoggedIn, true);
    return null;
  }

  /// Returns null on success, error message on failure.
  Future<String?> login(String username, String password) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_keyUsername);
    final storedPw = p.getString(_keyPassword);
    if (stored == null) return 'No account found. Please register first.';
    if (stored != username.trim() || storedPw != password) return 'Incorrect username or password';
    await p.setBool(_keyLoggedIn, true);
    return null;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyLoggedIn, false);
    await p.remove(_keyOnboarded);
  }

  Future<bool> get hasAccount async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyUsername) != null;
  }
}
