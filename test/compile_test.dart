import 'package:dartle_c/src/helpers.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('can split compiler command from args', () {
    var (cmd, args) = splitCommand('gcc');
    expect(cmd, equals(('gcc')));
    expect(args, isEmpty);

    (cmd, args) = splitCommand('zig cc');
    expect(cmd, equals(('zig')));
    expect(args, equals(['cc']));

    (cmd, args) = splitCommand('zig cc -v');
    expect(cmd, equals(('zig')));
    expect(args, equals(['cc', '-v']));
  });
}
