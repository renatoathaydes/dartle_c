import 'package:dartle_c/src/compile.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('can split compiler command from args', () {
    var (cmd, args) = splitCompilerCmd('gcc');
    expect(cmd, equals(('gcc')));
    expect(args, isEmpty);

    (cmd, args) = splitCompilerCmd('zig cc');
    expect(cmd, equals(('zig')));
    expect(args, equals(['cc']));

    (cmd, args) = splitCompilerCmd('zig cc -v');
    expect(cmd, equals(('zig')));
    expect(args, equals(['cc', '-v']));
  });
}
