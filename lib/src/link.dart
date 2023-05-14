import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:path/path.dart' as paths;

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
        .where((f) => paths.extension(f.path) == '.o')
        .toList();
    return await execProc(
      Process.start(compiler, [
        ...args,
        ...linkerArgs,
        '-o',
        binaryOutputFile,
        ...objectFiles.map((f) => f.path),
      ]),
      successMode: StreamRedirectMode.stdoutAndStderr,
    );
  }
}
