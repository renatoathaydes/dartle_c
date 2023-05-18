import 'dart:io';

Future<Map<String, Set<String>>?> computeDependencyTree(
    String objectsOutputDir) async {
  final outDir = Directory(objectsOutputDir);
  if (!await outDir.exists()) {
    return null;
  }
  final result = <String, Set<String>>{};
  await for (final file in outDir.list()) {
    if (file is File && file.path.endsWith('.d')) {
      final (outFile, deps) =
          _parseMakeFileDependencies(await file.readAsString());

      if (deps.isNotEmpty) {
        // the output file depends on everything the Makefile lists
        result[outFile] = deps.toSet();
      }

      // the Make file lists the actual source as the first dependency,
      // and the next files are the ones the source includes (i.e. depends on).
      if (deps.length < 2) continue;
      result[deps.first] = deps.skip(1).toSet();
    }
  }
  return result;
}

(String, Iterable<String>) _parseMakeFileDependencies(String line) {
  final startIndex = line.indexOf(':');
  if (startIndex > 0 && startIndex < line.length - 1) {
    final output = line.substring(0, startIndex);
    final deps = line.substring(startIndex + 1).trim().split(' ');
    return (output, deps);
  }
  throw StateError('Cannot parse Makefile dependency: "$line"');
}
