import 'dart:io' show exit, File;

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:dartle_c/dartle_c.dart';
import 'package:logging/logging.dart';

final logger = Logger('dartle-c');

String version() => '''
DartleC version: $dartlecVersion
Dartle version: $dartleVersion
''';

String help() => '''
${version()}
https://github.com/renatoathaydes/dartle_c

Usage: dcc [<options>] [<tasks>]

Runs a DartleC build.
Configuration can be provided via task arguments or via the
dcc.yaml file.

Options:
$optionsDescription
''';

Future<void> main(List<String> args) async {
  final stopwatch = Stopwatch()..start();
  final options = parseOptions(args);
  activateLogging(options.logLevel);

  if (options.showHelp) {
    print(help());
  } else if (options.showVersion) {
    return print(version());
  }
  try {
    await runBuild(options, stopwatch);
  } on DartleException catch (e, st) {
    if (logger.isLoggable(Level.FINE)) {
      logger.severe(e.message, e, st);
    } else {
      logger.severe(e.message);
    }
    exit(e.exitCode);
  }
}

Future<void> runBuild(Options options, Stopwatch stopwatch) async {
  // configure DartleC
  final configFile = File('dcc.yaml');
  final config = (await configFile.exists())
      ? loadConfigFromYaml(configFile)
      : loadConfigFromYamlText('{}');

  logger.log(
      profile,
      () => 'Parsed dc configuration in '
          '${stopwatch.elapsedMilliseconds}ms');
  logger.fine(() => '$config');

  final dartlec = config.toDartleC();

  // add a clean task to the build
  final clean = createCleanTask(
      name: 'cleanC',
      tasks: dartlec.tasks,
      description: 'Deletes the outputs of all other tasks.');

  // run Dartle build!
  await runBasic({...dartlec.tasks, clean}, {dartlec.linkC}, options,
      DartleCache.instance);

  logger.info(ColoredLogMessage(
      'Build SUCCESS in ${elapsedTime(stopwatch)}.', LogColor.green));
}
