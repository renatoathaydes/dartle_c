import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:path/path.dart' as paths;
import 'package:test/test.dart';

import '../example/dartle_c_example.dart' as ex;

final sourceDir = paths.join('test', 'src');
final binaryOutputFile = paths.join('test', 'a.out');
final objectsOutputDir = paths.join('test', 'out');

void main() {
  group('DartleC', () {
    setUp(_cleanup);
    tearDown(_cleanup);

    test('Compiles C files into executable', () async {
      await ex.runBuild(const Options(),
          sourceDir: sourceDir,
          binaryOutputFile: binaryOutputFile,
          objectsOutputDir: objectsOutputDir);

      expect(await File(binaryOutputFile).exists(), isTrue);
    });
  });
}

Future<void> _cleanup() async {
  await ignoreExceptions(
      () => Directory(objectsOutputDir).delete(recursive: true));
  await ignoreExceptions(() =>
      Directory(paths.join('test', '.dartle_tool')).delete(recursive: true));
  await ignoreExceptions(() => File(binaryOutputFile).delete());
}
