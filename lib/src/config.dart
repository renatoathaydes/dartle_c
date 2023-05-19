import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:dartle_c/dartle_c.dart';
import 'package:yaml/yaml.dart';

/// The location of the sources to compile.
sealed class Sources {
  FileCollection toFileCollection();
}

/// Enumerate source files explicitly.
final class SourceFiles implements Sources {
  /// Source files to compile.
  final List<String> sourceFiles;

  const SourceFiles(this.sourceFiles);

  @override
  FileCollection toFileCollection() => files(sourceFiles);

  @override
  String toString() {
    return 'SourceFiles($sourceFiles)';
  }
}

/// Enumerate source directories so DartleC will find source files to compile
/// within them, recursively.
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

/// DartleC Configuration data.
typedef DartleCConfig = ({
  String? compiler,
  List<String> compilerArgs,
  List<String> linkerArgs,
  String objectsOutputDir,
  Sources sources,
  String binaryOutputFile,
  YamlMap completeMap,
});

extension DartleCConfigFunctions on DartleCConfig {
  /// Use this DartleC Configuration data object to create a [DartleC] instance.
  DartleC toDartleC() {
    return DartleC(
      sources.toFileCollection(),
      binaryOutputFile,
      objectsOutputDir: objectsOutputDir,
      compiler: compiler,
      compilerArgs: compilerArgs,
      linkerArgs: linkerArgs,
    );
  }
}

/// Load the DartleC Configuration.
DartleCConfig loadConfigFromYaml(File file) {
  final doc = loadYaml(file.readAsStringSync(), sourceUrl: Uri.file(file.path));
  return _loadConfig(doc);
}

/// Load the DartleC Configuration.
DartleCConfig loadConfigFromYamlText(String text) {
  final doc = loadYaml(text);
  return _loadConfig(doc);
}

DartleCConfig _loadConfig(dynamic doc) {
  if (doc is! YamlMap) {
    final type = doc?.runtimeType;
    throw DartleException(message: 'YAML should evaluate to a Map, not $type');
  }
  return (
    compiler: _stringOrError(doc, 'compiler'),
    compilerArgs: _stringsOrError(doc, 'compiler-args'),
    linkerArgs: _stringsOrError(doc, 'linker-args'),
    objectsOutputDir: _stringOrError(doc, 'objects-dir', defaultValue: 'out')!,
    sources: _sources(doc, 'source-files', 'source-dirs'),
    binaryOutputFile: _stringOrError(doc, 'output', defaultValue: 'a.out')!,
    completeMap: doc,
  );
}

String? _stringOrError(YamlMap doc, String field, {String? defaultValue}) {
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

String _stringItemOrError(int index, dynamic item, String field) {
  if (item is String) {
    return item;
  }
  final type = item?.runtimeType;
  throw DartleException(
      message: '"$field" item ($type) at index $index should be a String');
}

List<String> _stringsOrError(YamlMap doc, String field) {
  final value = doc[field];
  switch (value) {
    case String s:
      return [s];
    case YamlList list:
      return list.toListOfStrings(field);
    case null:
      return const [];
    default:
      final type = value.runtimeType;
      throw DartleException(
          message: '"$field" ($type) should be a List of String');
  }
}

Sources _sources(YamlMap doc, String sourceFilesField, String sourceDirsField) {
  final sourceFiles = doc[sourceFilesField];
  final sourceDirs = doc[sourceDirsField];
  switch ((sourceFiles, sourceDirs)) {
    case (String s, null):
      return SourceFiles([s]);
    case (null, String s):
      return SourceDirectories([s]);
    case (YamlList list, null):
      return SourceFiles(list.toListOfStrings(sourceFilesField));
    case (null, YamlList list):
      return SourceDirectories(list.toListOfStrings(sourceDirsField));
    case (null, null):
      return const SourceDirectories(['src']);
    case (Object, Object):
      throw DartleException(
          message: 'Only one of "$sourceFilesField" and '
              '"$sourceDirsField" must be provided');
    default:
      final filesType = sourceFiles?.runtimeType;
      final dirsType = sourceDirs?.runtimeType;
      throw DartleException(
          message: '"$sourceFilesField" ($filesType) and '
              '"$sourceDirsField" ($dirsType)'
              'must be of type List of String');
  }
}

extension on YamlList {
  List<String> toListOfStrings(String field) {
    return indexed.map((e) => _stringItemOrError(e.$1, e.$2, field)).toList();
  }
}
