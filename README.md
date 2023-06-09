# DartleC

[![DartleC CI](https://github.com/renatoathaydes/dartle_c/workflows/DartleC%20Build/badge.svg)](https://github.com/renatoathaydes/dartle_c/actions)
[![pub package](https://img.shields.io/pub/v/dartle_c.svg)](https://pub.dev/packages/dartle_c)

A [Dartle](https://renatoathaydes.github.io/dartle-website/) extension to compile C projects.

It compiles C code into object files incrementally (`compileC` task),
then generates a binary executable from the object files (`linkC` task).

DartleC can be used as a command-line utility, `dcc`, or as a Dartle library (to integrate with other Dartle-based tools).

## Using the executable `dcc`

DartleC can be used as a command-line utility to compile C code.

To use it in that way, [activate](https://dart.dev/tools/pub/cmd/pub-global) it with `pub`:

```shell
dart pub global activate dartle_c
```

After this, running `dcc` will compile all C files found in a `src` directory to the `out` dir,
generating a binary executable named `a.out`.

### Tasks

* `compileC` - Compiles C source code into object files.
* `linkC` - Links object files, creating a binary executable.
* `archiveObjects` - Archives object files, creating a static library.
* `cleanC` - Deletes the outputs of all other tasks.

Both `linkC` and `archiveObjects` depend on `compileC`, with `linkC` being the default task.
Hence, running `dcc` without arguments will invoke the `compileC` and `linkC` tasks, as necessary.

To only compile the C source files without generating an executable,
and using a specific `cstd` version, as an example:

```shell
dcc compileC :-cstd=c99
```

> The `:` before the argument to the `compileC` task is necessary because otherwise
> Dartle uses the argument instead of passing it on to the task.

Notice that Dartle allows calling tasks by typing only their partial names, so for example,
the `compileC` task can be run by typing `dcc comp` or `dcc coC`. To run `linkC`, if no
extra tasks are added, requires only `dcc l` (as no other tasks start with an `l`).

To run the archive task, it's enough to invoke `dcc ar`.

Useful options:

```shell
# show usage and available options
dcc -h

# show all tasks
dcc -s

# enable verbose (`debug`) output
dcc -l debug
```

### Configuring `dcc`

To configure `dcc`, create a `dcc.yaml` file at the project root directory with contents as shown
below (all properties are optional):

```yaml
compiler: gcc
compiler-args: [ "-std=c2x", "-Wall", "-Wextra", "-Werror", "-ansi", "-pedantic" ]
linker-args: [ "-shared" ]
objects-dir: out
source-dirs: [ src ]

# instead of source-dirs, you can also list files explicitly:
# source-files: [foo.c, bar.c]

output: my-binary

archiver: ar
archiver-args: [ "-v" ]
archive: out/libmylib.a
```

> The `compiler` is chosen depending on the platform if not provided.
> You can also set the `CC` environment variable to choose one.
> Similarly, the archiver can be set with the `AR` environment variable.

Task arguments are added to the respective `*-args` provided in the YAML configuration file.

## Using `DartleC` as a library.

To include `DartleC` in your existing Dartle build, or to write your own build system based on
`DartleC`, add it as a dependency of your Dart project:

```shell
dart pub add dartle_c
```

Check this [project's example](example/dartle_c_example.dart) for how to use its API.
