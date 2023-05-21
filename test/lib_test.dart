import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:test/test.dart';

final dcc = File('bin/dcc.dart').absolute.path;

const libDir = 'test/single_hfile_example';
const libOutDir = '$libDir/out';
const libFile = '$libOutDir/libmylib.so';
const libUserDir = 'test/uses_hfile_example';
const libUserOutDir = '$libUserDir/out';
const libUserMain = '$libUserOutDir/main';

Future<int> _runBuild(List<String> args, String workingDir) {
  return execProc(Process.start(
      'dart', [dcc, '--no-color', '-l', 'debug', ...args],
      workingDirectory: workingDir));
}

String _ldLibEnvVarName() {
  if (Platform.isMacOS) return 'DYLD_LIBRARY_PATH';
  if (Platform.isWindows) return 'PATH';
  return 'LD_LIBRARY_PATH';
}

void main() {
  group('DartleC Executable', () {
    setUp(_cleanup);
    tearDown(_cleanup);

    test('Can compile shared library and use it on an application', () async {
      // build the lib
      expect(await _runBuild(const [], libDir), equals(0));
      expect(File(libFile).existsSync(), isTrue);

      // build the main
      expect(await _runBuild(const [], libUserDir), equals(0));
      expect(File(libUserMain).existsSync(), isTrue);

      // setup the load path for finding the dynamic library
      final loadLibVarName = _ldLibEnvVarName();
      final currentLoadLibVar = Platform.environment[loadLibVarName];
      final newLibVar = [
        if (currentLoadLibVar != null) currentLoadLibVar,
        Directory(libOutDir).absolute.path,
      ].join(Platform.pathSeparator);

      // run main loading the dynamic library
      await execProc(
          Process.start(libUserMain, const [], environment: {
            loadLibVarName: newLibVar,
          }),
          // the binary should exit with 3
          isCodeSuccessful: (code) => code == 3);
    });
  });
}

Future<void> _cleanup() async {
  await ignoreExceptions(() => Directory(libOutDir).delete(recursive: true));
  await ignoreExceptions(
      () => Directory(libUserOutDir).delete(recursive: true));
  await ignoreExceptions(
      () => Directory('$libDir/.dartle_tool').delete(recursive: true));
  await ignoreExceptions(
      () => Directory('$libUserDir/.dartle_tool').delete(recursive: true));
}
