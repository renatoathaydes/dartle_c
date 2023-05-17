import 'dart:io';

import 'package:dartle/dartle.dart';
import 'package:path/path.dart' as paths;
import 'package:yaml/yaml.dart';

const taskName = 'generateVersionFile';
const _pubspec = 'pubspec.yaml';
final _versionFile = paths.join('lib', 'src', 'version.g.dart');

final generateVersionFileTask = Task(
  _generateVersionFile,
  name: taskName,
  description: 'Generates the version file.',
  runCondition:
      RunOnChanges(inputs: file(_pubspec), outputs: file(_versionFile)),
);

Future<void> _generateVersionFile(List<String> _) async {
  final version = loadYaml(await File(_pubspec).readAsString())['version'];
  await File(_versionFile).writeAsString("const dartlecVersion = '$version';");
}
