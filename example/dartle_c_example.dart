import 'dart:io' show exit;

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:dartle_c/dartle_c.dart';
import 'package:logging/logging.dart';

final logger = Logger('dartle_c_example');

/// This example passes the command arguments directly to Dartle,
/// using DartleC with a default configuration and tasks,
/// plus a `clean` task.
Future<void> main(List<String> args) async {
  final options = parseOptions(args);
  activateLogging(options.logLevel);
  try {
    await runBuild(options);
  } on DartleException catch (e, st) {
    if (logger.isLoggable(Level.FINE)) {
      logger.severe(e.message, e, st);
    } else {
      logger.severe(e.message);
    }
    exit(e.exitCode);
  }
}

Future<void> runBuild(
  Options options, {
  String sourceDir = 'src',
  String binaryOutputFile = 'a.out',
  String objectsOutputDir = 'out',
}) async {
  // configure DartleC
  final dartlec = DartleC(
    dir(sourceDir, fileExtensions: const {'.c'}),
    binaryOutputFile,
    objectsOutputDir: objectsOutputDir,
    compilerArgs: const ['-Wall'],
  );

  // add a clean task to the build
  final clean = createCleanTask(tasks: dartlec.tasks);

  // run Dartle build!
  await runBasic({...dartlec.tasks, clean}, {dartlec.linkC}, options,
      DartleCache.instance);

  logger.info(ColoredLogMessage('Build SUCCESS', LogColor.green));
}
