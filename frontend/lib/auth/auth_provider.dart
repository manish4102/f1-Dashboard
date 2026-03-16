import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(apiProvider));
});

class AuthState {
  final bool loading;
  final String? token;
  final String? error;

  const AuthState({this.loading = false, this.token, this.error});

  bool get isAuthed => token != null && token!.isNotEmpty;

  AuthState copyWith({bool? loading, String? token, String? error}) {
    return AuthState(
      loading: loading ?? this.loading,
      token: token ?? this.token,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final ApiClient api;
  AuthController(this.api) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString("auth_token");
    if (t != null && t.isNotEmpty) {
      state = state.copyWith(token: t);
    }
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove("auth_token");
    state = const AuthState();
  }

  Future<void> _setToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString("auth_token", token);
    state = state.copyWith(token: token, loading: false, error: null);
  }

  Future<void> devLogin() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await api.devLogin();
      await _setToken(res.token);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      await devLogin();
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await api.login(email.trim().toLowerCase(), password);
      await _setToken(res.token);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signup(String email, String password, String confirm) async {
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      await devLogin();
      return;
    }
    if (password != confirm) {
      state = state.copyWith(error: "Passwords do not match");
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await api.signup(email.trim().toLowerCase(), password);
      await _setToken(res.token);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}