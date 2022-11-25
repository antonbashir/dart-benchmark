import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:benchmark/storage/bindings.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption("count", abbr: "c");
  final parsed;
  try {
    parsed = parser.parse(args);
  } catch (exception) {
    print("usage: ${parser.usage}");
    exit(-1);
  }
  final countString = parsed["count"];
  if (countString == null) {
    print("usage: ${parser.usage}");
    exit(-1);
  }
  final count = int.tryParse(countString);
  if (count == null) {
    print("usage: ${parser.usage}");
    exit(-1);
  }
  final bindings = BenchmarkBindings(DynamicLibrary.open("${Directory.current.path}/bin/libbenchmark.so"));
  final completer = Completer();
  var element = 0;
  final port = ReceivePort();
  port.listen((message) {
    if (++element >= count) completer.complete(null);
  });
  final stopwatch = Stopwatch();
  stopwatch.start();
  bindings.dart_run_benchmark(count, port.sendPort.nativePort);
  await completer.future;
  print("Benchmark finished at ${stopwatch.elapsed} seconds");
  exit(0);
}
