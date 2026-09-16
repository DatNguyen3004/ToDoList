import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService(this._client);

  static const mobileRedirectUrl = 'io.tdl.app://login-callback';

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<User?> refreshCurrentUser() async {
    if (_client.auth.currentSession == null) return null;
    return (await _client.auth.getUser()).user;
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : mobileRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
