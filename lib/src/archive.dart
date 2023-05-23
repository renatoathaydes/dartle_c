import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:path/path.dart' as paths;

import 'config.dart';
import 'helpers.dart';
import 'logger.dart';

class Archiver {
  final FileCollection objectsOutput;
  final DartleCache cache;
  late final FileCollection outputs;
  late final List<String> archiverArgs;
  late final String archiver;
  late final String output;

  Archiver(this.cache, this.objectsOutput,
      [String? output, String? archiver, this.archiverArgs = const []]) {
    this.archiver = _selectArchiver(archiver);
    this.output = _chooseArchive(output);
    outputs = file(this.output);

    logger.fine(() => 'Selected Archiver: ${this.archiver}');
  }

  RunCondition get runCondition =>
      RunOnChanges(inputs: objectsOutput, outputs: outputs, cache: cache);

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<void> archive(List<String> args) async {
    final objectFiles = await objectsOutput
        .resolveFiles()
        .asyncMap((f) => f.path)
        .asyncExpand<String>((p) =>
            p.endsWith(objectFileExtension) ? Stream.value(p) : Stream.empty())
        .toSet();
    logger.fine(() => 'Archiving object files: $objectFiles');

    if (objectFiles.isEmpty) {
      failBuild(reason: 'Nothing to do, no object files provided');
    }

    logger.info(() => 'Creating archive "$output"');

    final outputFile = File(output);
    try {
      await outputFile.delete();
      logger.finer(() => 'Deleted existing archive');
    } on Exception {
      // file did not exist, so maybe need to create parent dir
      await File(output).parent.create(recursive: true);
    }

    final (archive, lastArgs) = splitCommand(archiver);

    final allArgs = [
      ...archiverArgs,
      ...args,
      ..._selectArgs(lastArgs),
      ...objectFiles,
    ];

    logger.fine(() => 'Archiver command: $archive ${allArgs.join(' ')}');

    await execProc(
      Process.start(archive, allArgs, workingDirectory: Directory.current.path),
      successMode: StreamRedirectMode.stdoutAndStderr,
    );
  }

  List<String> _selectArgs(List<String> configArgs) {
    if (configArgs.isEmpty) {
      return [
        '-qsc',
        output,
      ];
    }
    return configArgs;
  }
}

String _chooseArchive(String? output) {
  return output ?? "lib${paths.basename(Directory.current.path)}.a";
}

String _selectArchiver(String? configArchiver) {
  if (configArchiver != null) {
    return _validateArchiver(configArchiver, source: 'config file');
  }
  final cc = Platform.environment['AR'];
  if (cc != null) return _validateArchiver(cc, source: 'AR env-var');
  // TODO what to do on Windows?
  return 'ar';
}

String _validateArchiver(String archiver, {required String source}) {
  final trimmed = archiver.trim();
  if (trimmed.isEmpty) {
    throw DartleException(
        message: 'Archiver resolved from $source into an empty string');
  }
  return trimmed;
}
