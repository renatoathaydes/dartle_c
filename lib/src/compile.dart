import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:path/path.dart' as paths;

import 'dependencies.dart';
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
      final dependencyTree = await computeDependencyTree(objectsOutputDir);
      if (dependencyTree != null) {
        logger.fine(() => 'Dependency tree: $dependencyTree');
        final incSources =
            await _sourcesForIncrementalCompilation(changeSet, dependencyTree);
        if (incSources == null) {
          logger.info('Cannot perform incremental compilation');
        } else {
          sources = incSources;
          logger.fine(() => 'Compiling incrementally: $sources');
        }
      }
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

  Future<Set<String>?> _sourcesForIncrementalCompilation(
      ChangeSet changeSet, Map<String, Set<String>> dependencyTree) async {
    var sources = <String>{};
    final deletedFiles = changeSet.inputChanges
        .where((f) => f.kind == ChangeKind.deleted)
        .map((f) => f.entity.path)
        .toSet();
    for (final change in changeSet.inputChanges) {
      if (change.entity is! File) continue;
      switch (change.kind) {
        case ChangeKind.modified || ChangeKind.added:
          await _addWithDependentsTo(
              sources, change.entity.path, deletedFiles, dependencyTree);
          break;
        case ChangeKind.deleted:
          ignoreExceptions(() async => await File(paths.join(objectsOutputDir,
                  paths.setExtension(paths.basename(change.entity.path), '.o')))
              .delete());
      }
    }
    for (final change in changeSet.outputChanges) {
      if (change.entity is! File) continue;
      final deleted = paths.basename(change.entity.path);
      final sourceDeps = dependencyTree[deleted];
      if (sourceDeps == null) {
        logger.fine('Missing dependency file for $deleted');
        // don't know the object file dependencies, cannot do incremental compilation
        return null;
      } else {
        logger.fine('Deleted file $deleted has dependencies: $sourceDeps');
        // only the direct source dependency needs to be recompiled
        final source = sourceDeps.firstOrNull;
        if (source != null && !deletedFiles.contains(source)) {
          sources.add(source);
        }
      }
    }
    return sources;
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
Future<void> _addWithDependentsTo(Set<String> sources, String path,
    Set<String> deletedFiles, Map<String, Set<String>> dependencyTree) async {
  final cpath = _withCExtension(path);
  final dependents = _dependents(cpath, dependencyTree)
      .where((f) => !deletedFiles.contains(f));
  logger.fine(() => 'Source $cpath has dependents: $dependents');
  sources.add(cpath);
  sources.addAll(dependents);
}

Iterable<String> _dependents(
    String path, Map<String, Set<String>> dependencyTree) {
  return dependencyTree.entries
      .where((e) => paths.extension(e.key) == '.c' && e.value.contains(path))
      .map((e) => e.key);
}

String _withCExtension(String path) {
  if (paths.extension(path) == '.c') {
    return path;
  }
  return paths.setExtension(path, '.c');
}
