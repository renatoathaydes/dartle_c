import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:path/path.dart' as paths;

import 'file_collection.dart';
import 'logger.dart';

class CCompiler {
  final List<String> compilerArgs;
  final FileCollection sourceFiles;
  final String objectsOutputDir;
  final DartleCache cache;
  late final FileCollection outputs;

  CCompiler(this.sourceFiles, this.cache, this.objectsOutputDir,
      [this.compilerArgs = const []]) {
    outputs = CachedFileCollection(
        dir(objectsOutputDir, fileExtensions: const {'.o', '.d'}));
  }

  RunCondition get runCondition =>
      RunOnChanges(inputs: sourceFiles, outputs: outputs, cache: cache);

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<int> compile(List<String> args, [ChangeSet? changeSet]) async {
    final originalSources =
        await sourceFiles.resolveFiles().asyncMap((f) => f.path).toSet();
    logger.fine(() => 'Original source files: $originalSources');
    logger.info(() => 'Compiling object files into $objectsOutputDir');
    var sources = originalSources;
    if (changeSet != null) {
      sources = <String>{};
      var missingDependenciesFile = false;
      final deletedFiles = changeSet.inputChanges
          .where((f) => f.kind == ChangeKind.deleted)
          .map((f) => f.entity.path)
          .toSet();
      for (final change in changeSet.inputChanges) {
        if (change.entity is! File) continue;
        switch (change.kind) {
          case ChangeKind.modified:
          case ChangeKind.added:
            missingDependenciesFile |= await _addWithDependentsTo(
                sources, change.entity.path, deletedFiles, objectsOutputDir);
            break;
          case ChangeKind.deleted:
            ignoreExceptions(() async => await File(paths.join(
                    objectsOutputDir,
                    paths.setExtension(
                        paths.basename(change.entity.path), '.o')))
                .delete());
        }
        if (missingDependenciesFile) {
          // cannot continue with incremental compilation
          sources = originalSources;
          break;
        }
      }
      for (final change in changeSet.outputChanges) {
        if (change.entity is! File) continue;
        final source = paths.relative(
            paths.setExtension(change.entity.path, '.c'),
            from: objectsOutputDir);
        if (originalSources.contains(source)) {
          await _addWithDependentsTo(
              sources, source, deletedFiles, objectsOutputDir);
        }
      }
      logger.fine(() => 'Compiling incrementally: $sources');
    }

    if (sources.isEmpty) {
      failBuild(reason: 'Nothing to do, no source files provided');
    }

    await Directory(objectsOutputDir).create(recursive: true);

    try {
      return await execProc(Process.start(
          'gcc',
          [
            ...compilerArgs,
            ...args,
            '-MMD',
            '-c',
            ...sources,
          ],
          workingDirectory: Directory.current.path));
    } finally {
      await _moveObjectsTo(objectsOutputDir, sources);
    }
  }
}

Future<void> _moveObjectsTo(
    String objectsOutputDir, Set<String> sources) async {
  for (final source in sources) {
    final obj = File(paths.setExtension(paths.basename(source), '.o'));
    final dFile = File(paths.setExtension(paths.basename(source), '.d'));
    obj.rename(paths.join(objectsOutputDir, obj.path));
    dFile.rename(paths.join(objectsOutputDir, dFile.path));
  }
}

/// Return true if the .d file is missing, false otherwise.
Future<bool> _addWithDependentsTo(Set<String> sources, String path,
    Set<String> deletedFiles, String objectsOutputDir) async {
  final dFile = File(paths.join(
      objectsOutputDir, paths.setExtension(paths.basename(path), '.d')));
  if (!await dFile.exists()) {
    logger.warning(() => 'Missing .d file: ${dFile.path}');
    return true;
  }
  final dependents = _parseMakeFileDependents(await dFile.readAsString())
      .where((f) => !deletedFiles.contains(f) && paths.extension(f) == '.c');
  logger.fine(() => 'Source $path has dependents: $dependents');
  sources.add(path);
  sources.addAll(dependents);
  return false;
}

Iterable<String> _parseMakeFileDependents(String line) {
  final startIndex = line.indexOf(':') + 2;
  if (startIndex > 2) {
    return line.substring(startIndex).trimRight().split(' ');
  }
  failBuild(reason: '.d file has invalid line: "$line"');
}
