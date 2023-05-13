# DartleC

A [Dartle](https://renatoathaydes.github.io/dartle-website/) extension to compile C projects.

## Using the executable `dcc`

DartleC can be used as a command-line utility to compile C code.

To use it in that way, activate it with `pub`:

```shell
dart pub global activate dartle_c
```

After this, running `dcc` will copmile all C files found in a `src` directory to the `out` dir,
generating a binary executable named `a.out`.

### Configuring `dcc`

To configure `dcc`, create a `dcc.yaml` file at the project root directory with contents as shown
below (all options are optional):

```yaml
compiler: gcc
compiler-args: [-Wall]
objects-dir: out
source-dirs: [src]

# instead of source-dirs, you can also list files explicitly:
# source-files: [foo.c, bar.c]

output: my-binary
```

Options can also be passed to the `DartleC` tasks.
For example, to pass an option to the C Compiler via the CLI:

```shell
$ dcc compile :-std=c99
```

> CLI options are added to the `compiler-args` provided in the YAML configuration file.

## Using `DartleC` as a library.

To include `DartleC` in your existing Dartle build, or to write your own build system based on
`DartleC`, check this [project example](example/dartle_c_example.dart).
