import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle_c/dartle_c.dart';
import 'package:yaml/yaml.dart';

sealed class Sources {
  FileCollection toFileCollection();
}

final class SourceFiles implements Sources {
  final List<String> sourceFiles;

  const SourceFiles(this.sourceFiles);

  @override
  FileCollection toFileCollection() => files(sourceFiles);

  @override
  String toString() {
    return 'SourceFiles($sourceFiles)';
  }
}

final class SourceDirectories implements Sources {
  final List<String> directories;

  const SourceDirectories(this.directories);

  @override
  FileCollection toFileCollection() =>
      dirs(directories, fileExtensions: const {'.c', '.h'});

  @override
  String toString() {
    return 'SourceDirectories(${toFileCollection()})';
  }
}

typedef DartleCConfig = ({
  String? compiler,
  List<String> compilerArgs,
  List<String> linkerArgs,
  String objectsOutputDir,
  Sources sources,
  String binaryOutputFile,
});

extension DartleCConfigFunctions on DartleCConfig {
  DartleC toDartleC() {
    return DartleC(
      sources.toFileCollection(),
      binaryOutputFile,
      objectsOutputDir: objectsOutputDir,
      compiler: compiler,
      compilerArgs: compilerArgs,
    );
  }
}

DartleCConfig loadConfigFromYaml(File file) {
  final doc = loadYaml(file.readAsStringSync(), sourceUrl: Uri.file(file.path));
  return _loadConfig(doc);
}

DartleCConfig loadConfigFromYamlText(String text) {
  final doc = loadYaml(text);
  return _loadConfig(doc);
}

DartleCConfig _loadConfig(dynamic doc) {
  return (
    compiler: _stringOrError(doc, 'compiler'),
    compilerArgs: _stringsOrError(doc, 'compiler-args'),
    linkerArgs: _stringsOrError(doc, 'linker-args'),
    objectsOutputDir: _stringOrError(doc, 'objects-dir', defaultValue: 'out')!,
    sources: _sources(doc, 'source-files', 'source-dirs'),
    binaryOutputFile: _stringOrError(doc, 'output', defaultValue: 'a.out')!,
  );
}

String? _stringOrError(dynamic doc, String field, {String? defaultValue}) {
  final value = doc[field];
  switch (value) {
    case String s:
      return s;
    case List<String> list when list.length == 1:
      return list.first;
    case null:
      return defaultValue;
    default:
      throw DartleException(message: '"$field" should be a String');
  }
}

List<String> _stringsOrError(dynamic doc, String field) {
  final value = doc[field];
  switch (value) {
    case String s:
      return [s];
    case List<String> list:
      return list;
    case null:
      return const [];
    default:
      throw DartleException(message: '"$field" should be a List of String');
  }
}

Sources _sources(dynamic doc, String sourceFilesField, String sourceDirsField) {
  final sourceFiles = doc[sourceFilesField];
  final sourceDirs = doc[sourceDirsField];
  switch ((sourceFiles, sourceDirs)) {
    case (String s, null):
      return SourceFiles([s]);
    case (null, String s):
      return SourceDirectories([s]);
    case (List<String> list, null):
      return SourceFiles(list);
    case (null, List<String> list):
      return SourceDirectories(list);
    case (null, null):
      return const SourceDirectories(['src']);
    case (Object, Object):
      throw DartleException(
          message: 'Only one of "$sourceFilesField" and '
              '"$sourceDirsField" must be provided');
    default:
      throw DartleException(
          message: '"$sourceFilesField" and "$sourceDirsField" '
              'must be a List of String');
  }
}
