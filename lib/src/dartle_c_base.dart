import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle/dartle_cache.dart';

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

  /// The Dartle cache being used.
  final DartleCache cache;

  /// The compileC task.
  late final Task compileC;

  /// The linkC task.
  late final Task linkC;

  /// All tasks.
  late Set<Task> tasks;

  DartleC(this.sourceFiles, this.binaryOutputFile,
      {this.objectsOutputDir,
      this.compiler,
      this.compilerArgs = const [],
      DartleCache? cache})
      : cache = cache ?? DartleCache.instance {
    final cachedSourceFiles = CachedFileCollection(sourceFiles);
    final objDir = objectsOutputDir ?? Directory.current.path;

    final cc = CCompiler(
        cachedSourceFiles, this.cache, objDir, compiler, compilerArgs);

    final linker = Linker(cc.outputs, binaryOutputFile, cc.compiler);

    compileC = _createCompileTask(cc);
    linkC = _createLinkTask(linker);
    tasks = {compileC, linkC};
  }

  Task _createCompileTask(CCompiler compiler) {
    return Task(compiler.compile,
        name: 'compileC',
        description: 'Compiles C source code into object files.',
        runCondition: compiler.runCondition,
        argsValidator: compiler.argsValidator);
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
