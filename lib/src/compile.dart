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
  late final String compiler;
  late final FileCollection outputs;

  CCompiler(this.sourceFiles, this.cache, this.objectsOutputDir,
      [String? compiler, this.compilerArgs = const []]) {
    this.compiler = compiler ?? _selectCompiler();

    // FIXME parse .d files to figure out actual dependencies?
    outputs = CachedFileCollection(
        dir(objectsOutputDir, fileExtensions: const {'.o', '.d'}));

    logger.fine(() => 'Selected C Compiler: ${this.compiler}');
  }

  RunCondition get runCondition =>
      RunOnChanges(inputs: sourceFiles, outputs: outputs, cache: cache);

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<int> compile(List<String> args, [ChangeSet? changeSet]) async {
    final originalSources =
        await sourceFiles.resolveFiles().asyncMap((f) => f.path).toSet();
    logger.fine(() => 'Original source files: $originalSources');
    logger.info(() => 'Compiling object files into directory '
        '"$objectsOutputDir"');
    Iterable<String> sources = originalSources.where((p) => p.endsWith('.c'));
    if (changeSet != null) {
      final dependencyTree = await computeDependencyTree(objectsOutputDir);
      if (dependencyTree != null) {
        logger.fine(() => 'Dependency tree: $dependencyTree');
        final incrementalSources =
            (await _computeFilesToCompile(changeSet, dependencyTree).toSet())
                .where((e) => e.endsWith('.c'));
        if (incrementalSources.isEmpty) {
          logger.info('Cannot perform incremental compilation');
        } else {
          sources = incrementalSources;
          logger.fine(() => 'Compiling incrementally: $sources');
        }
      }
    }

    if (sources.isEmpty) {
      failBuild(reason: 'Nothing to do, no source files provided');
    }

    await Directory(objectsOutputDir).create(recursive: true);

    final allArgs = [...compilerArgs, ...args, '-MMD', '-c', ...sources];

    logger.fine(() => 'Compiler command: $compiler ${allArgs.join(' ')}');

    try {
      return await execProc(
        Process.start(compiler, allArgs,
            workingDirectory: Directory.current.path),
        successMode: StreamRedirectMode.stdoutAndStderr,
      );
    } finally {
      await _moveObjectsTo(objectsOutputDir, sources);
    }
  }

  Stream<String> _computeFilesToCompile(
      ChangeSet changeSet, Map<String, Set<String>> dependencyTree) async* {
    // collect the deleted files to avoid trying to re-compile any
    final deletedFiles = changeSet.inputChanges
        .where((f) => f.kind == ChangeKind.deleted)
        .map((f) => f.entity.path)
        .toSet();

    for (final change in changeSet.inputChanges) {
      switch (change.kind) {
        case ChangeKind.modified || ChangeKind.added:
          yield change.entity.path;
          for (final dep in _dependents(change.entity.path, dependencyTree)) {
            if (!deletedFiles.contains(dep)) yield dep;
          }
          break;
        case ChangeKind.deleted:
          // must delete the output file from all deleted sources
          await ignoreExceptions(() async =>
              await File(paths.setExtension(change.entity.path, '.o'))
                  .delete());
      }
    }
  }
}

Future<void> _moveObjectsTo(
    String objectsOutputDir, Iterable<String> sources) async {
  final cSources = sources.where((e) => e.endsWith('.c')).toSet();
  logger
      .fine(() => 'Moving ${2 * cSources.length} file(s) to $objectsOutputDir');
  for (final source in cSources) {
    final obj = File(paths.setExtension(paths.basename(source), '.o'));
    final dFile = File(paths.setExtension(paths.basename(source), '.d'));
    logger.finer(
        () => 'Moving ${obj.path} and ${dFile.path} to $objectsOutputDir');
    await obj.rename(paths.join(objectsOutputDir, obj.path));
    await dFile.rename(paths.join(objectsOutputDir, dFile.path));
  }
}

Iterable<String> _dependents(
    String path, Map<String, Set<String>> dependencyTree) {
  return dependencyTree.entries
      .where((e) => e.value.contains(path))
      .map((e) => e.key);
}

String _selectCompiler() {
  final cc = Platform.environment['CC'];
  if (cc != null) return cc;
  if (Platform.isWindows || Platform.isMacOS) return 'clang';
  if (Platform.isLinux) return 'gcc';
  throw StateError('Cannot select C compiler for this Platform. '
      'Please set the CC environment variable or provide a `compiler` '
      'explicitly when creating DartleC.');
}
