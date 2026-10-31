import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gustaro/src/recent/recent_scans.dart';

void main() {
  late UserDatabase db;
  late DateTime now;
  RecentScansStore store({int limit = 50}) =>
      RecentScansStore(db, limit: limit, clock: () => now);

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 10, 1, 12);
  });
  tearDown(() => db.close());

  void tick() => now = now.add(const Duration(minutes: 1));

  test('lists newest first', () async {
    final s = store();
    await s.record(1);
    tick();
    await s.record(2);
    expect((await s.list()).map((r) => r.vintageId), [2, 1]);
  });

  test(
    'viewing again moves an entry to the top without duplicating it',
    () async {
      final s = store();
      await s.record(1);
      tick();
      await s.record(2);
      tick();
      await s.record(1);
      final list = await s.list();
      expect(list.map((r) => r.vintageId), [1, 2]);
      expect(list.first.viewedAt.isAtSameMomentAs(now), isTrue);
    },
  );

  test('keeps only the newest [limit] entries', () async {
    final s = store(limit: 3);
    for (var id = 1; id <= 5; id++) {
      await s.record(id);
      tick();
    }
    expect((await s.list()).map((r) => r.vintageId), [5, 4, 3]);
  });

  test('clear removes everything', () async {
    final s = store();
    await s.record(1);
    await s.clear();
    expect(await s.list(), isEmpty);
  });

  test('remembers the liked answer across views, and can forget it', () async {
    final s = store();
    await s.record(1);
    await s.setLiked(1, true);
    tick();
    await s.record(1);
    expect((await s.list()).single.liked, isTrue);
    await s.setLiked(1, null);
    expect((await s.list()).single.liked, isNull);
  });

  test('remove deletes one entry', () async {
    final s = store();
    await s.record(1);
    await s.record(2);
    await s.remove(1);
    expect((await s.list()).map((r) => r.vintageId), [2]);
  });

  test('settings read, overwrite and clear', () async {
    final settings = SettingsStore(db);
    expect(await settings.read('a'), isNull);
    await settings.write('a', '1');
    await settings.write('a', '2');
    expect(await settings.read('a'), '2');
    await settings.clear();
    expect(await settings.read('a'), isNull);
  });
}
