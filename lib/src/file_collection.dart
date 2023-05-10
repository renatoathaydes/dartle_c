import 'dart:io';

import 'package:dartle/dartle.dart';

/// Caches result of calling [resolveFiles] so that it will only resolve
/// files from the delegate once.
class CachedFileCollection extends FileCollection {
  final FileCollection delegate;
  List<File>? _files;

  CachedFileCollection(this.delegate);

  @override
  List<DirectoryEntry> get directories => delegate.directories;

  @override
  Set<String> get files => delegate.files;

  @override
  Stream<File> resolveFiles() async* {
    var cached = _files;
    if (cached == null) {
      cached = await delegate.resolveFiles().toList();
      _files = cached;
    }
    yield* Stream.fromIterable(cached);
  }
}
