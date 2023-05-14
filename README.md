# DartleC

![DartleC CI](https://github.com/renatoathaydes/dartle/workflows/Dartle%20Build/badge.svg)
[![pub package](https://img.shields.io/pub/v/dartle_c.svg)](https://pub.dev/packages/dartle_c)

A [Dartle](https://renatoathaydes.github.io/dartle-website/) extension to compile C projects.

## Using the executable `dcc`

DartleC can be used as a command-line utility to compile C code.

To use it in that way, [activate](https://dart.dev/tools/pub/cmd/pub-global) it with `pub`:

```shell
dart pub global activate dartle_c
```

After this, running `dcc` will compile all C files found in a `src` directory to the `out` dir,
generating a binary executable named `a.out`.

### Configuring `dcc`

To configure `dcc`, create a `dcc.yaml` file at the project root directory with contents as shown
below (all options are optional):

```yaml
compiler: gcc
compiler-args: ["-std=c2x", "-Wall", "-Werror", "-ansi", "-pedantic"]
objects-dir: out
source-dirs: [src]

# instead of source-dirs, you can also list files explicitly:
# source-files: [foo.c, bar.c]

output: my-binary
```

> The `compiler` is chosen depending on the platform if not provided.
> You can also set the `CC` environment variable to choose one.

Options can also be passed to the `DartleC` tasks.
For example, to pass an option to the C Compiler via the CLI:

```shell
$ dcc compile :-std=c99
```

> CLI options are added to the `compiler-args` provided in the YAML configuration file.

## Using `DartleC` as a library.

To include `DartleC` in your existing Dartle build, or to write your own build system based on
`DartleC`, check this [project's example](example/dartle_c_example.dart).
