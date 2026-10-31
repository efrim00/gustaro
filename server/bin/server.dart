import 'dart:io';

import 'package:gustaro_server/admin_api.dart';
import 'package:gustaro_server/admin_auth.dart';
import 'package:gustaro_server/apple.dart';
import 'package:gustaro_server/bootstrap.dart';
import 'package:gustaro_server/catalog_api.dart';
import 'package:gustaro_server/config.dart';
import 'package:gustaro_server/database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  final env = Platform.environment;
  final url = requireEnv(env, 'DATABASE_URL');
  final port = int.parse(env['PORT'] ?? '8080');

  final pool = await openPool(url);
  await migrate(pool);
  await seedIfEmpty(pool, File('seed/catalog.json'));

  final handlers = <Handler>[catalogHandler(pool)];
  try {
    final apple = AppleConfig.fromEnv(env);
    final auth = AdminAuth(
      pool,
      apple: apple,
      bootstrapCode: env['BOOTSTRAP_CODE'],
    );
    final router = Router()
      ..get('/auth/apple/start', auth.start)
      ..get('/auth/apple/callback', auth.callback);
    handlers
      ..add(router.call)
      ..add(
        AdminApi(
          pool,
          auth,
          baseUrl: apple.baseUrl,
          page: File('web/admin.html'),
        ).handler,
      );
  } on StateError catch (error) {
    // Closed, not open: without sign-in the admin area does not exist.
    stderr.writeln('Admin area disabled: ${error.message}');
  }

  var cascade = Cascade();
  for (final handler in handlers) {
    cascade = cascade.add(handler);
  }
  final handler = const Pipeline()
      .addMiddleware(_safeErrors())
      .addMiddleware(_securityHeaders())
      .addHandler(cascade.handler);
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Gustaro API listening on ${server.port}');
}

/// Errors reach the server log only, never the caller.
Middleware _safeErrors() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } catch (error) {
        stderr.writeln('error: ${error.runtimeType}');
        return Response.internalServerError(body: 'Server error');
      }
    };

Middleware _securityHeaders() =>
    (inner) => (request) async {
      final response = await inner(request);
      return response.change(
        headers: {
          'x-content-type-options': 'nosniff',
          'strict-transport-security': 'max-age=31536000',
        },
      );
    };
