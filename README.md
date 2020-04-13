# About Pubspec Version Scanner
This little utility scans given directories and recursively finds any [Dart](https://dartlang.org) pubspec.yaml files.  Any files located are parsed for the name and version.  The utility then generates a 'packages_g.dart' file that contains of map of the name/version found within each pubspec.

# Usage
```
-h, --help                      Displays usage information.
-v, --version                   Displays version for this program.
-f, --from=<path,path, ...>     Path(s) with pubspec.yaml file.  Defaults to current directory.
-o, --out=<path>                Path to output the 'packages_g.dart' file.  Defaults to current directory.
-r, --[no-]recursive            Crawls subdirectories of any given paths and includes any pubspecs found.
                                (defaults to on)
```

# Example
Given the following pubspec.yaml file that exists in the current directory:
```
name: pubspec_version_scanner
version: 1.0.0
```

Command:
```
dart pvs.dart --out lib
```

Will generate the following file in lib\packages_g.dart

```
// Generated code by Dart Package Version Builder

const packages = const <String, String> {
	"pubspec_version_scanner" : "1.0.0",
};
```

The file can then be imported into your own Dart project and referenced at runtime:

```
import "package:pubspec_version_scanner/packages_g.dart";

void main() {
    print("Version of this library is ${packages['package_ver']}");
}
```