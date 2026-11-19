import 'package:flutter/services.dart';

Future<String?> readDeviceTimeZoneId() async {
  try {
    return await const MethodChannel('health_journal/device_time_zone')
        .invokeMethod<String>('read');
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
