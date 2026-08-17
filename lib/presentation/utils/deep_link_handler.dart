import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static void init({
    required Function(String token) onInvitationTokenReceived,
  }) {
    // 1. Check initial link if app was launched via URL
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleUri(uri, onInvitationTokenReceived);
      }
    });

    // 2. Listen to incoming deep links while app is open
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri, onInvitationTokenReceived);
      },
      onError: (err) {
        // Log deep link error silently
      },
    );
  }

  static void _handleUri(Uri uri, Function(String token) callback) {
    if (uri.path.contains('/invite') || uri.host == 'invite' || uri.queryParameters.containsKey('token')) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        callback(token);
      }
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
