import 'package:dartle/dartle.dart';
import 'dart:io';
import 'package:path/path.dart' as paths;

class Linker {
  final String binaryOutputFile;
  final FileCollection inputs;

  const Linker(this.inputs, this.binaryOutputFile);

  RunCondition get runCondition =>
      RunOnChanges(outputs: file(binaryOutputFile));

  ArgsValidator get argsValidator => const AcceptAnyArgs();

  Future<int> link(List<String> args) async {
    final objectFiles = await inputs
        .resolveFiles()
        .where((f) => paths.extension(f.path) == '.o')
        .toList();
    return await execProc(Process.start('gcc',
        [...args, '-o', binaryOutputFile, ...objectFiles.map((f) => f.path)]));
  }
}
