import 'dart:js_interop';

// Defined in web/index.html. Resolves to true once `google.maps` is usable,
// re-injecting the Maps script if the first load failed.
@JS('rakniEnsureGoogleMaps')
external JSPromise<JSBoolean>? _rakniEnsureGoogleMaps();

Future<bool> ensureGoogleMapsLoaded() async {
  try {
    final promise = _rakniEnsureGoogleMaps();
    if (promise == null) return false;
    return (await promise.toDart).toDart;
  } catch (_) {
    return false;
  }
}
