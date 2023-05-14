import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:path/path.dart' as paths;

class Linker {
  final String binaryOutputFile;
  final FileCollection inputs;
  final String compiler;

  const Linker(this.inputs, this.binaryOutputFile, this.compiler);

  RunCondition get runCondition =>
      RunOnChanges(outputs: file(binaryOutputFile));

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<int> link(List<String> args) async {
    final objectFiles = await inputs
        .resolveFiles()
        .where((f) => paths.extension(f.path) == '.o')
        .toList();
    return await execProc(Process.start(compiler,
        [...args, '-o', binaryOutputFile, ...objectFiles.map((f) => f.path)]));
  }
}
