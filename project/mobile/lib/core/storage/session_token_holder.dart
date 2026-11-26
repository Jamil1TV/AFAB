/// Holds the short-lived JWT access token (15m TTL) and CSRF fallback nonce
/// strictly in RAM — never persisted to SharedPreferences or plaintext storage.
class SessionTokenHolder {
  String? _accessToken;
  String? _csrfToken;

  String? get accessToken => _accessToken;
  String? get csrfToken => _csrfToken;
  bool get hasAccessToken => _accessToken != null && _accessToken!.isNotEmpty;

  void setTokens({String? accessToken, String? csrfToken}) {
    if (accessToken != null && accessToken.isNotEmpty) {
      _accessToken = accessToken;
    }
    if (csrfToken != null && csrfToken.isNotEmpty) {
      _csrfToken = csrfToken;
    }
  }

  void clear() {
    _accessToken = null;
    _csrfToken = null;
  }
}
