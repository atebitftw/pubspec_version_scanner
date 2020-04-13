library pvs;

import 'dart:io';
import 'package:args/args.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:pubspec_version_scanner/packages_g.dart';

void main(List<String> args) {
  final parser = _initArgParser();

  ArgResults results;

  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stdout.writeln("$e");
    exit(1);
  } catch (e) {
    stdout.writeln("Unrecognized Error: $e");
    exit(2);
  }

  if (results == null) {
    _usage(parser);
    exit(1);
  }

  if (results["help"]) {
    _usage(parser);
    exit(0);
  }

  if (results["version"]) {
    stdout.writeln("Version: ${packages['package_ver']}");
    exit(0);
  }

  final packageList =
      _generateList(results["from"], recurse: results["recursive"]);

  if (packageList.isEmpty) {
    stdout.writeln("No packages found.  No file generated.");
    exit(0);
  }

  _writePackages(results["out"], packageList);

  stdout.writeln(
      "Found ${packageList.length} packages. File generation complete.");
}

Map<String, String> _generateList(List<String> paths, {bool recurse: false}) {
  final finalList = Map<String, String>();

  if (paths.isEmpty) {
    paths.add(null);
  }

  for (var path in paths) {
    if (path == null) {
      path = Directory.current.path;
    }

    final dir = Directory.fromUri(Uri.file(path, windows: true));

    if (!dir.existsSync()) {
      stdout.writeln("WARNING: Path '$path' not found.  Skipping.");
      continue;
    }

    final list = dir
        .listSync(recursive: recurse)
        .where((f) => f.uri.path.contains("pubspec.yaml"));

    for (final file in list) {
      final fileData = _getFile(file.path);
      final result = Pubspec.parse(fileData);
      finalList[result.name] = result.version.toString();
    }
  }

  return finalList;
}

void _writePackages(String outputDir, Map<String, String> packages) async {
  if (outputDir == null) {
    outputDir = Directory.current.path;
  }

  final buffer = StringBuffer();

  buffer.writeln("// Generated code by Dart Package Version Builder");
  buffer.writeln("");
  //buffer.writeln("part 'packages.dart';");
  buffer.writeln("");
  // Could just emit the toString() but doing this for pretty-print
  buffer.writeln("const packages = const <String, String> {");
  for (final key in packages.keys) {
    buffer.writeln("\t\"$key\" : \"${packages[key]}\",");
  }
  buffer.writeln("};");

  try {
    stdout.writeln("Generating file to '${outputDir}${Platform.pathSeparator}packages_g.dart'.");
    final writer = File("${outputDir}${Platform.pathSeparator}packages_g.dart");
    final handle = writer.openWrite();
    writer.writeAsStringSync(buffer.toString());
    await handle.close();
  } on FileSystemException catch (e) {
    stdout.writeln("File IO error occured: $e");
  }
}

ArgParser _initArgParser() {
  final parser = ArgParser();

  parser.addFlag("help",
      abbr: "h",
      help: "Displays usage information.",
      defaultsTo: false,
      negatable: false);
  parser.addFlag("version",
      abbr: "v",
      help: "Displays version for this program.",
      defaultsTo: false,
      negatable: false);
  parser.addMultiOption("from",
      abbr: "f",
      valueHelp: "path, path, ...",
      help: "Path(s) with pubspec.yaml file.  Defaults to current directory.");
  parser.addOption("out",
      abbr: "o",
      valueHelp: "path",
      help:
          "Path to output the 'packages_g.dart' file.  Defaults to current directory.");
  // parser.addOption("lib",
  // abbr: "l",
  // valueHelp: "library",
  // help: "When specified, generates a 'part of' directive in the generated file that refers to the library.");
  parser.addFlag("recursive",
      abbr: "r",
      defaultsTo: true,
      negatable: true,
      help:
          "Crawls subdirectories of any given paths and includes any pubspecs found.");

  return parser;
}

void _usage(ArgParser parser) {
  stdout.writeln("Dart Package Version Builder");
  stdout.writeln("");
  stdout.writeln(
      "Generates a Dart file that contains package name and version number for any pubspec.yaml file(s) found.");
  stdout.writeln("");
  stdout.writeln("Usage: ");
  stdout.writeln(parser.usage);
}

String _getFile(String filePathAndName) {
  final file = File.fromUri(Uri.file(filePathAndName, windows: true));
  final fileData = file.readAsStringSync();
  return fileData;
}
