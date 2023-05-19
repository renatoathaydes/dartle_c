import 'package:dartle_c/dartle_c.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('can load config from YAML', () {
    final conf = '''
    compiler: gcc
    source-dirs: [lib]
    objects-dir: objects
    compiler-args: ["-std=c2x", "-Wall", "-Wextra", "-Werror"]
    linker-args: ["-shared"]
    output: mylib
    ''';
    final config = loadConfigFromYamlText(conf);

    expect(config.compiler, equals('gcc'));
    expect(
        config.sources,
        isA<SourceDirectories>().having(
            (dirs) => dirs.directories, 'directories', equals(['lib'])));
    expect(config.objectsOutputDir, equals('objects'));
    expect(config.compilerArgs,
        equals(["-std=c2x", "-Wall", "-Wextra", "-Werror"]));
    expect(config.linkerArgs, equals(['-shared']));
    expect(config.binaryOutputFile, equals('mylib'));
  });

  test('loads default values if not given config values', () {
    final config = loadConfigFromYamlText('a: 1');

    expect(config.compiler, isNull);
    expect(
        config.sources,
        isA<SourceDirectories>().having(
            (dirs) => dirs.directories, 'directories', equals(['src'])));
    expect(config.objectsOutputDir, equals('out'));
    expect(config.compilerArgs, isEmpty);
    expect(config.linkerArgs, isEmpty);
    expect(config.binaryOutputFile, equals('a.out'));
  });

  test('can set source-files', () {
    final config = loadConfigFromYamlText('source-files: [a.c, b.h]');

    expect(config.compiler, isNull);
    expect(
        config.sources,
        isA<SourceFiles>().having(
            (dirs) => dirs.sourceFiles, 'files', equals(['a.c', 'b.h'])));
    expect(config.objectsOutputDir, equals('out'));
    expect(config.compilerArgs, isEmpty);
    expect(config.linkerArgs, isEmpty);
    expect(config.binaryOutputFile, equals('a.out'));
  });
}
