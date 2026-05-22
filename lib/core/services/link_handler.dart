import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:rakni_v2/core/services/auth_service.dart';

class LinkHandler {
  LinkHandler._internal();
  static final LinkHandler instance = LinkHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  void init() {
    // 1. Handle deep link when the app is already open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    }, onError: (err) {
      // Handle exception by logging or showing a message
    });

    // 2. Handle deep link when the app is started by the link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleLink(uri);
      }
    });
  }

  void _handleLink(Uri uri) {
    final link = uri.toString();
    if (AuthService.instance.isSignInWithEmailLink(link)) {
      AuthService.instance.signInWithEmailLink(link).then((credential) {
        // Successfully signed in. 
        // AuthGate will automatically redirect to Home based on authStateChanges.
      }).catchError((error) {
        // Handle error (e.g., link expired)
      });
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
