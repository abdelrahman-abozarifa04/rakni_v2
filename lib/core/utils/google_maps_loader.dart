// Ensures the Google Maps JS SDK is available before a GoogleMap is built.
// On web, building a GoogleMap while `google.maps` is undefined throws
// "Cannot read properties of undefined (reading 'MapTypeId')".
export 'google_maps_loader_stub.dart'
    if (dart.library.js_interop) 'google_maps_loader_web.dart';
