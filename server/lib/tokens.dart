import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// 256 random bits, URL-safe.
String newToken() => base64Url
    .encode([for (var i = 0; i < 32; i++) _random.nextInt(256)])
    .replaceAll('=', '');

/// What is stored instead of a token or code.
String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();

/// Compares without stopping at the first difference.
bool constantTimeEquals(String a, String b) {
  final x = utf8.encode(a);
  final y = utf8.encode(b);
  var diff = x.length ^ y.length;
  for (var i = 0; i < x.length && i < y.length; i++) {
    diff |= x[i] ^ y[i];
  }
  return diff == 0;
}
