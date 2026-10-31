import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS features with no plugin: on-device text recognition (Apple Vision)
/// and opening the app's page in Settings.
abstract final class NativeBridge {
  static const _channel = MethodChannel('gustaro/native');

  /// All text recognized in the image file at [path]; empty if none.
  static Future<String> recognizeText(String path) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return '';
    return await _channel.invokeMethod<String>('recognizeText', path) ?? '';
  }

  static Future<void> openSettings() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _channel.invokeMethod<void>('openSettings');
  }
}
