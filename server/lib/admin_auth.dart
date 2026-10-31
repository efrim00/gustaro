import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import 'apple.dart';
import 'tokens.dart';

const sessionCookie = '__Host-gustaro';
const _sessionLifetime = Duration(hours: 12);
const _attemptLifetime = Duration(minutes: 10);
const _inviteLifetime = Duration(days: 2);

/// The signed-in editor of a request.
class Editor {
  const Editor(this.id, this.role);
  final int id;
  final String role;
  bool get isOwner => role == 'owner';
}

/// Sign in with Apple for editors. Only people already invited can get in.
class AdminAuth {
  AdminAuth(
    this.pool, {
    required this.apple,
    this.bootstrapCode,
    this.exchange = exchangeCode,
  });

  final Pool<void> pool;
  final AppleConfig apple;

  /// Lets the very first editor in, once, while there are no editors.
  final String? bootstrapCode;
  final AppleTokenExchange exchange;

  /// Sends the browser to Apple. [invite] is only checked after Apple has
  /// said who the user is.
  Future<Response> start(Request request) async {
    final state = newToken();
    final nonce = newToken();
    final invite = request.url.queryParameters['invite'];
    await pool.execute(
      Sql.named(
        'INSERT INTO auth_attempt (state_hash, nonce, invite_hash, expires_at) '
        'VALUES (@s, @n, @i, @e)',
      ),
      parameters: {
        's': sha256Hex(state),
        'n': nonce,
        'i': invite == null || invite.isEmpty ? null : sha256Hex(invite),
        'e': DateTime.now().add(_attemptLifetime).toUtc(),
      },
    );
    return Response.found(apple.authorizeUrl(state: state, nonce: nonce));
  }

  Future<Response> callback(Request request) async {
    final query = request.url.queryParameters;
    final code = query['code'];
    final state = query['state'];
    if (code == null || state == null) return _denied();

    // One use only: the attempt is gone once read.
    final attempt = await pool.execute(
      Sql.named(
        'DELETE FROM auth_attempt WHERE state_hash = @s AND expires_at > now() '
        'RETURNING nonce, invite_hash',
      ),
      parameters: {'s': sha256Hex(state)},
    );
    if (attempt.isEmpty) return _denied();

    final String sub;
    try {
      final idToken = await exchange(apple, code);
      sub = subjectFromIdToken(idToken, apple, attempt.single[0] as String);
    } on Object catch (error) {
      stderr.writeln('sign-in failed: ${error.runtimeType}');
      return _denied();
    }

    final editor = await _editorFor(sub, attempt.single[1] as String?);
    if (editor == null) return _denied();

    final token = newToken();
    await pool.execute(
      Sql.named(
        'INSERT INTO editor_session (token_hash, editor_id, expires_at) '
        'VALUES (@t, @e, @x)',
      ),
      parameters: {
        't': sha256Hex(token),
        'e': editor.id,
        'x': DateTime.now().add(_sessionLifetime).toUtc(),
      },
    );
    await pool.execute('DELETE FROM editor_session WHERE expires_at < now()');
    return Response.found(
      '/admin',
      headers: {'set-cookie': _cookie(token, _sessionLifetime)},
    );
  }

  Future<Editor?> _editorFor(String sub, String? inviteHash) async {
    final known = await pool.execute(
      Sql.named('SELECT id, role FROM editor WHERE apple_sub = @s'),
      parameters: {'s': sub},
    );
    if (known.isNotEmpty) {
      return Editor(known.single[0] as int, known.single[1] as String);
    }
    if (inviteHash == null) return null;

    return pool.runTx((tx) async {
      // Two first sign-ins at once must not both become owner.
      await tx.execute('LOCK TABLE editor IN SHARE ROW EXCLUSIVE MODE');
      String? role;
      final bootstrap = bootstrapCode;
      final noEditors =
          (await tx.execute('SELECT count(*) FROM editor')).single[0] == 0;
      if (noEditors &&
          bootstrap != null &&
          constantTimeEquals(inviteHash, sha256Hex(bootstrap))) {
        role = 'owner';
      } else {
        final invite = await tx.execute(
          Sql.named(
            'UPDATE editor_invite SET used_at = now() '
            'WHERE code_hash = @h AND used_at IS NULL AND expires_at > now() '
            'RETURNING role',
          ),
          parameters: {'h': inviteHash},
        );
        if (invite.isNotEmpty) role = invite.single[0] as String;
      }
      if (role == null) return null;
      final created = await tx.execute(
        Sql.named(
          'INSERT INTO editor (apple_sub, role) VALUES (@s, @r) RETURNING id',
        ),
        parameters: {'s': sub, 'r': role},
      );
      return Editor(created.single[0] as int, role);
    });
  }

  /// The editor behind the request's cookie, or null.
  Future<Editor?> editorOf(Request request) async {
    final token = _cookieValue(request.headers['cookie'], sessionCookie);
    if (token == null) return null;
    final rows = await pool.execute(
      Sql.named(
        'SELECT e.id, e.role FROM editor_session s '
        'JOIN editor e ON e.id = s.editor_id '
        'WHERE s.token_hash = @t AND s.expires_at > now()',
      ),
      parameters: {'t': sha256Hex(token)},
    );
    if (rows.isEmpty) return null;
    return Editor(rows.single[0] as int, rows.single[1] as String);
  }

  Future<Response> logout(Request request) async {
    final token = _cookieValue(request.headers['cookie'], sessionCookie);
    if (token != null) {
      await pool.execute(
        Sql.named('DELETE FROM editor_session WHERE token_hash = @t'),
        parameters: {'t': sha256Hex(token)},
      );
    }
    return Response.ok(
      'ok',
      headers: {'set-cookie': _cookie('', Duration.zero)},
    );
  }

  /// A one-time code that lets one more person become an editor.
  Future<String> createInvite(String role) async {
    final code = newToken();
    await pool.execute(
      Sql.named(
        'INSERT INTO editor_invite (code_hash, role, expires_at) '
        'VALUES (@h, @r, @e)',
      ),
      parameters: {
        'h': sha256Hex(code),
        'r': role,
        'e': DateTime.now().add(_inviteLifetime).toUtc(),
      },
    );
    return code;
  }

  // The same answer for every failure, so nothing is revealed.
  Response _denied() => Response(
    403,
    body: 'Sign-in was not possible.',
    headers: {'content-type': 'text/plain; charset=utf-8'},
  );
}

String _cookie(String value, Duration maxAge) =>
    '$sessionCookie=$value; Max-Age=${maxAge.inSeconds}; Path=/; Secure; '
    'HttpOnly; SameSite=Strict';

String? _cookieValue(String? header, String name) {
  if (header == null) return null;
  for (final part in header.split(';')) {
    final pair = part.trim().split('=');
    if (pair.length >= 2 && pair.first == name) return pair.skip(1).join('=');
  }
  return null;
}
