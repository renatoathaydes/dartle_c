import 'package:dartle/dartle_dart.dart';

import 'dartle-src/generateVersion.dart' as genVer;

final dartleDart = DartleDart();

void main(List<String> args) {
  dartleDart.formatCode.dependsOn(const {genVer.taskName});
  run(args, tasks: {
    ...dartleDart.tasks,
    genVer.generateVersionFileTask,
  }, defaultTasks: {
    dartleDart.build
  });
}
