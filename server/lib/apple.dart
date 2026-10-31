import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// Everything needed to sign a user in with Apple. [fromEnv] throws when a
/// value is missing, so the admin area stays closed instead of half-open.
class AppleConfig {
  AppleConfig({
    required this.teamId,
    required this.keyId,
    required this.clientId,
    required this.privateKey,
    required this.baseUrl,
  });

  factory AppleConfig.fromEnv(Map<String, String> env) => AppleConfig(
    teamId: requireEnv(env, 'APPLE_TEAM_ID'),
    keyId: requireEnv(env, 'APPLE_KEY_ID'),
    clientId: requireEnv(env, 'APPLE_CLIENT_ID'),
    privateKey: requireEnv(env, 'APPLE_PRIVATE_KEY'),
    baseUrl: requireEnv(env, 'PUBLIC_BASE_URL'),
  );

  final String teamId;
  final String keyId;
  final String clientId;
  final String privateKey;
  final String baseUrl;

  String get redirectUri => '$baseUrl/auth/apple/callback';

  Uri authorizeUrl({required String state, required String nonce}) =>
      Uri.https('appleid.apple.com', '/auth/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'state': state,
        'nonce': nonce,
      });

  /// Apple wants a short-lived token signed with our key as the "password".
  String clientSecret() =>
      JWT(
        {},
        issuer: teamId,
        subject: clientId,
        audience: Audience.one('https://appleid.apple.com'),
        header: {'kid': keyId},
      ).sign(
        ECPrivateKey(privateKey),
        algorithm: JWTAlgorithm.ES256,
        expiresIn: const Duration(minutes: 5),
      );
}

/// Lets tests replace the call to Apple.
typedef AppleTokenExchange = Future<String> Function(
  AppleConfig config,
  String code,
);

/// Trades the one-time [code] for Apple's id token (a JWT).
Future<String> exchangeCode(AppleConfig config, String code) async {
  final response = await http
      .post(
        Uri.https('appleid.apple.com', '/auth/token'),
        body: {
          'client_id': config.clientId,
          'client_secret': config.clientSecret(),
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': config.redirectUri,
        },
      )
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw StateError('Apple refused the code (${response.statusCode}).');
  }
  final token = (jsonDecode(response.body) as Map<String, dynamic>)['id_token'];
  if (token is! String) throw StateError('Apple sent no id_token.');
  return token;
}

/// The user id from Apple's [idToken], after checking who it is for and that
/// it is fresh. The token came straight from Apple over TLS in exchange for
/// our one-time code, so its signature need not be checked again (OpenID
/// Connect Core 3.1.3.7).
String subjectFromIdToken(String idToken, AppleConfig config, String nonce) {
  final parts = idToken.split('.');
  if (parts.length != 3) throw const FormatException('Malformed token.');
  final claims = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, dynamic>;
  final exp = claims['exp'];
  final aud = claims['aud'];
  final sub = claims['sub'];
  if (claims['iss'] != 'https://appleid.apple.com' ||
      aud != config.clientId ||
      claims['nonce'] != nonce ||
      sub is! String ||
      sub.isEmpty ||
      exp is! int ||
      DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isBefore(DateTime.now())) {
    throw const FormatException('Token is not valid for this app.');
  }
  return sub;
}
