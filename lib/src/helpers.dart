(String, List<String>) splitCommand(String command) {
  if (command.contains(' ')) {
    final ([compile, ...args]) =
        command.split(' ').map((s) => s.trim()).toList();
    return (compile, args);
  }
  return (command, const []);
}
