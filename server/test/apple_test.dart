import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:gustaro_server/apple.dart';
import 'package:gustaro_server/tokens.dart';
import 'package:test/test.dart';

String _idToken(Map<String, Object?> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'ES256'})}.${part(claims)}.sig';
}

/// A throwaway P-256 key, made with openssl (a tool every Mac has).
String _testKey() {
  final dir = Directory.systemTemp.createTempSync('gustaro_key');
  final raw = '${dir.path}/raw.pem';
  final key = '${dir.path}/key.p8';
  Process.runSync('openssl', [
    'ecparam',
    '-name',
    'prime256v1',
    '-genkey',
    '-noout',
    '-out',
    raw,
  ]);
  Process.runSync('openssl', [
    'pkcs8',
    '-topk8',
    '-nocrypt',
    '-in',
    raw,
    '-out',
    key,
  ]);
  final pem = File(key).readAsStringSync();
  dir.deleteSync(recursive: true);
  return pem;
}

void main() {
  final config = AppleConfig(
    teamId: 'TEAM123456',
    keyId: 'KEY1234567',
    clientId: 'com.example.admin',
    privateKey: _testKey(),
    baseUrl: 'https://api.example.com',
  );
  final future =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  Map<String, Object?> claims({
    Object? aud,
    Object? nonce,
    Object? iss,
    Object? exp,
  }) => {
    'iss': iss ?? 'https://appleid.apple.com',
    'aud': aud ?? 'com.example.admin',
    'nonce': nonce ?? 'n1',
    'exp': exp ?? future,
    'sub': '000123.abc',
  };

  test('takes the user id from a valid token', () {
    expect(subjectFromIdToken(_idToken(claims()), config, 'n1'), '000123.abc');
  });

  test('refuses tokens for another app, nonce, issuer, or an expired one', () {
    for (final bad in [
      claims(aud: 'com.other'),
      claims(nonce: 'other'),
      claims(iss: 'https://evil.example'),
      claims(exp: 1000),
    ]) {
      expect(
        () => subjectFromIdToken(_idToken(bad), config, 'n1'),
        throwsFormatException,
      );
    }
    expect(
      () => subjectFromIdToken('not.a-token', config, 'n1'),
      throwsFormatException,
    );
  });

  test('the client secret is a short ES256 token Apple can check', () {
    final jwt = JWT.decode(config.clientSecret());
    expect(jwt.header!['alg'], 'ES256');
    expect(jwt.header!['kid'], 'KEY1234567');
    final payload = jwt.payload as Map;
    expect(payload['iss'], 'TEAM123456');
    expect(payload['sub'], 'com.example.admin');
    expect(payload['aud'], 'https://appleid.apple.com');
    final lifetime = (payload['exp'] as int) - (payload['iat'] as int);
    expect(lifetime, lessThanOrEqualTo(600));
  });

  test('tokens are random, hashes are stable, comparison is exact', () {
    expect(newToken(), isNot(newToken()));
    expect(sha256Hex('a'), sha256Hex('a'));
    expect(sha256Hex('a'), isNot(sha256Hex('b')));
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'abcd'), isFalse);
  });
}
