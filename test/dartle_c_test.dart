import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as paths;
import 'package:test/test.dart';

import '../example/dartle_c_example.dart' as ex;

final sourceDir = paths.join('test', 'src');
final binaryOutputFile = paths.join('test', 'a.out');
final objectsOutputDir = paths.join('test', 'out');

void main() {
  group('DartleC', () {
    final helloO = File(paths.join(objectsOutputDir, 'hello.o'));
    final greetingO = File(paths.join(objectsOutputDir, 'greeting.o'));
    final helloc = File(paths.join(sourceDir, 'hello.c'));
    final greetingc = File(paths.join(sourceDir, 'greeting.c'));
    final greetingh = File(paths.join(sourceDir, 'greeting.h'));
    final greetingContent = greetingc.readAsStringSync();
    final greetinghContent = greetingh.readAsStringSync();
    final helloContent = helloc.readAsStringSync();

    tearDown(() async {
      await greetingc.writeAsString(greetingContent);
      await greetingh.writeAsString(greetinghContent);
      await helloc.writeAsString(helloContent);
    });

    setUp(_cleanup);
    tearDown(_cleanup);

    activateLogging(Level.FINE);

    test('Compiles C files into object files, links into executable', () async {
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      expect(
          await Directory(objectsOutputDir)
              .list(recursive: true)
              .map((f) => paths.basename(f.path))
              .toSet(),
          equals({'greeting.d', 'greeting.o', 'hello.d', 'hello.o'}));
      expect(await File(binaryOutputFile).exists(), isTrue);

      // test incremental compilation

      final helloOutTime = await helloO.lastModified();
      final greetingOutTime = await greetingO.lastModified();

      // compile again after changing only greeting.c
      await Future.delayed(Duration(seconds: 1));
      await greetingc.writeAsString('$greetingContent\n\n');
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      final helloOutTime2 = await helloO.lastModified();
      final greetingOutTime2 = await greetingO.lastModified();

      // only the greeting.c file is recompiled because
      // hello.c depends on the .h file, not the .c file
      expect(helloOutTime2, equals(helloOutTime));
      expect(greetingOutTime2, isAfter(greetingOutTime));

      // compile again after changing only greeting.h
      await Future.delayed(Duration(seconds: 1));
      await greetingh.writeAsString('$greetinghContent\n\n');
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      final helloOutTime3 = await helloO.lastModified();
      final greetingOutTime3 = await greetingO.lastModified();

      // only hello.c is recompiled
      expect(helloOutTime3, isAfter(helloOutTime2));
      expect(greetingOutTime3, equals(greetingOutTime2));

      // compile again after changing only hello.c
      await Future.delayed(Duration(seconds: 1));
      await helloc.writeAsString('$helloContent\n\n');
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      final helloOutTime4 = await helloO.lastModified();
      final greetingOutTime4 = await greetingO.lastModified();

      // only hello.c must be recompiled
      expect(helloOutTime4, isAfter(helloOutTime3));
      expect(greetingOutTime4, equals(greetingOutTime3));

      // deleting any output causes a full recompilation
      await Future.delayed(Duration(seconds: 1));
      await helloO.delete();
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      final helloOutTime5 = await helloO.lastModified();
      final greetingOutTime5 = await greetingO.lastModified();

      expect(helloOutTime5, isAfter(helloOutTime4));
      expect(greetingOutTime5, isAfter(greetingOutTime4));

      // finally, running it without modifying anything doesn't do anything
      await Future.delayed(Duration(seconds: 1));
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      final helloOutTime6 = await helloO.lastModified();
      final greetingOutTime6 = await greetingO.lastModified();

      expect(helloOutTime6, equals(helloOutTime5));
      expect(greetingOutTime6, equals(greetingOutTime5));
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}

Future<void> _cleanup() async {
  await ignoreExceptions(
      () => Directory(objectsOutputDir).delete(recursive: true));
  await ignoreExceptions(() =>
      Directory(paths.join('test', '.dartle_tool')).delete(recursive: true));
  await ignoreExceptions(() => File(binaryOutputFile).delete());
}

Matcher isAfter(DateTime other) => GreaterThanDateTimeMatcher(other);

class GreaterThanDateTimeMatcher extends Matcher {
  final DateTime other;

  GreaterThanDateTimeMatcher(this.other);

  @override
  Description describe(Description description) {
    return description.add('should be greater than $other');
  }

  @override
  bool matches(item, Map matchState) =>
      item is DateTime &&
      item.millisecondsSinceEpoch > other.millisecondsSinceEpoch;
}
