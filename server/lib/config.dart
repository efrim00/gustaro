import 'package:postgres/postgres.dart';

/// Reads [name] from the environment. Missing or empty is an error: the
/// server must not start with a guessed default.
String requireEnv(Map<String, String> env, String name) {
  final value = env[name];
  if (value == null || value.trim().isEmpty) {
    throw StateError('Missing required environment variable $name.');
  }
  return value;
}

/// Parses `postgresql://user:password@host:port/database`.
Endpoint endpointFromUrl(String url) {
  final uri = Uri.parse(url);
  if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
    throw FormatException('DATABASE_URL must start with postgresql://');
  }
  final userInfo = uri.userInfo.split(':');
  if (uri.host.isEmpty || uri.pathSegments.isEmpty || userInfo.length < 2) {
    throw FormatException('DATABASE_URL is missing host, database or login.');
  }
  return Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: uri.pathSegments.first,
    username: Uri.decodeComponent(userInfo.first),
    password: Uri.decodeComponent(userInfo.skip(1).join(':')),
  );
}

/// Railway's private network is not encrypted, everything else must be.
SslMode sslModeFor(Endpoint endpoint) =>
    endpoint.host.endsWith('.railway.internal')
    ? SslMode.disable
    : SslMode.require;
