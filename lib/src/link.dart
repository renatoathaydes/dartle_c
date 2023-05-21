import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle_c/dartle_c.dart';

import 'logger.dart';

class Linker {
  final String binaryOutputFile;
  final FileCollection inputs;
  final String compiler;
  final List<String> linkerArgs;

  const Linker(
      this.inputs, this.binaryOutputFile, this.compiler, this.linkerArgs);

  RunCondition get runCondition =>
      RunOnChanges(outputs: file(binaryOutputFile));

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<int> link(List<String> args) async {
    final objectFiles = await inputs
        .resolveFiles()
        .where((f) => f.path.endsWith(objectFileExtension))
        .toList();

    final allArgs = [
      ...args,
      ...linkerArgs,
      '-o',
      binaryOutputFile,
      ...objectFiles.map((f) => f.path),
    ];

    logger.fine(() => 'Compiler command: $compiler ${allArgs.join(' ')}');

    return await execProc(
      Process.start(compiler, allArgs),
      successMode: StreamRedirectMode.stdoutAndStderr,
    );
  }
}
