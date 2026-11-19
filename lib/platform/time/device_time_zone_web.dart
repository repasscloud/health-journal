import 'dart:js_interop';

@JS('Intl.DateTimeFormat')
extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external factory _DateTimeFormat();
  external _DateTimeOptions resolvedOptions();
}

extension type _DateTimeOptions._(JSObject _) implements JSObject {
  external JSString? get timeZone;
}

Future<String?> readDeviceTimeZoneId() async =>
    _DateTimeFormat().resolvedOptions().timeZone?.toDart;
