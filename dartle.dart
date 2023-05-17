import 'package:dartle/dartle_dart.dart';

import 'dartle-src/generate_version.dart' as gen;

final dartleDart = DartleDart();

void main(List<String> args) {
  dartleDart.formatCode.dependsOn(const {gen.taskName});
  run(args, tasks: {
    ...dartleDart.tasks,
    gen.generateVersionFileTask,
  }, defaultTasks: {
    dartleDart.build
  });
}
