import 'package:gustaro_server/config.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('a missing or empty variable stops the server', () {
    expect(() => requireEnv({}, 'DATABASE_URL'), throwsStateError);
    expect(
      () => requireEnv({'DATABASE_URL': ' '}, 'DATABASE_URL'),
      throwsStateError,
    );
    expect(requireEnv({'DATABASE_URL': 'x'}, 'DATABASE_URL'), 'x');
  });

  test('parses a database URL, including a password with colons', () {
    final e = endpointFromUrl(
      'postgresql://u:p%40ss:w@db.example.com:6543/gustaro',
    );
    expect(e.host, 'db.example.com');
    expect(e.port, 6543);
    expect(e.database, 'gustaro');
    expect(e.username, 'u');
    expect(e.password, 'p@ss:w');
  });

  test('rejects other URLs', () {
    expect(() => endpointFromUrl('mysql://u:p@h/d'), throwsFormatException);
    expect(() => endpointFromUrl('postgresql://h/d'), throwsFormatException);
  });

  test('only the private network skips encryption', () {
    expect(
      sslModeFor(Endpoint(host: 'postgres.railway.internal', database: 'd')),
      SslMode.disable,
    );
    expect(
      sslModeFor(Endpoint(host: 'db.example.com', database: 'd')),
      SslMode.require,
    );
  });
}
