import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';
import 'package:dartle_c/src/archive.dart';

import 'compile.dart';
import 'file_collection.dart';
import 'link.dart';

/// Dartle C extension.
class DartleC {
  /// The source files to compile. May include .c and .h files.
  final FileCollection sourceFiles;

  /// The optional output directory for object files.
  final String? objectsOutputDir;

  /// The path of the output binary executable file.
  final String binaryOutputFile;

  /// The C compiler to use.
  /// If null, the `CC` environment variable is used, and if that is not set,
  /// an appropriate compiler is chosen for the platform.
  final String? compiler;

  /// Extra compiler arguments.
  /// The `compileC` task also accepts compiler arguments.
  final List<String> compilerArgs;

  /// The file to store the compiled object files.
  final String? archiveFile;

  /// The object files archiver to use.
  /// If null, the `AR` environment variable is used, and if that is not set,
  /// an appropriate archiver is chosen for the platform.
  final String? archiver;

  /// Extra archiver arguments.
  /// The `archiveObjects` task also accepts archiver arguments.
  final List<String> archiverArgs;

  /// Extra linker arguments.
  /// The `linkC` task also accepts linker arguments.
  final List<String> linkerArgs;

  /// The Dartle cache being used.
  final DartleCache cache;

  /// The compileC task.
  late final Task compileC;

  /// The archiveObjects task.
  late final Task archiveObjects;

  /// The linkC task.
  late final Task linkC;

  /// All tasks.
  late Set<Task> tasks;

  DartleC(this.sourceFiles, this.binaryOutputFile,
      {this.objectsOutputDir,
      this.compiler,
      this.compilerArgs = const [],
      this.archiveFile,
      this.archiver,
      this.archiverArgs = const [],
      this.linkerArgs = const [],
      DartleCache? cache})
      : cache = cache ?? DartleCache.instance {
    final cachedSourceFiles = CachedFileCollection(sourceFiles);
    final objDir = objectsOutputDir ?? Directory.current.path;

    final cc = CCompiler(
        cachedSourceFiles, this.cache, objDir, compiler, compilerArgs);

    final ar =
        Archiver(this.cache, cc.outputs, archiveFile, archiver, archiverArgs);

    final linker =
        Linker(cc.outputs, binaryOutputFile, cc.compiler, linkerArgs);

    compileC = _createCompileTask(cc);
    archiveObjects = _createArchiverTask(ar);
    linkC = _createLinkTask(linker);
    tasks = {compileC, linkC, archiveObjects};
  }

  Task _createCompileTask(CCompiler compiler) {
    return Task(compiler.compile,
        name: 'compileC',
        description: 'Compiles C source code into object files.',
        runCondition: compiler.runCondition,
        argsValidator: compiler.argsValidator);
  }

  Task _createArchiverTask(Archiver archiver) {
    return Task(archiver.archive,
        name: 'archiveObjects',
        description: 'Archives object files into static library.',
        dependsOn: {compileC.name},
        runCondition: archiver.runCondition,
        argsValidator: archiver.argsValidator);
  }

  Task _createLinkTask(Linker linker) {
    return Task(linker.link,
        name: 'linkC',
        description: 'Links object files, creating a binary executable.',
        dependsOn: const {'compileC'},
        runCondition: linker.runCondition,
        argsValidator: linker.argsValidator);
  }
}
