import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:benchmark/storage/bindings.dart';

int? parseInt(ArgParser parser, ArgResults parsed, String name, {bool optional = false}) {
  final string = parsed[name];
  if (string == null) {
    if (optional) return null;
    print("usage:\n${parser.usage}");
    exit(-1);
  }
  final value = int.tryParse(string);
  if (value == null) {
    if (optional) return null;
    print("usage:\n${parser.usage}");
    exit(-1);
  }
  return value;
}

Future<void> main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption("count", abbr: "c");
  parser.addOption("isolates", abbr: "i", mandatory: false);
  ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } catch (exception) {
    print("usage:\n${parser.usage}");
    exit(-1);
  }

  final bindings = BenchmarkBindings(DynamicLibrary.open("${Directory.current.path}/bin/libbenchmark.so"));
  final completer = Completer();
  var element = 0;
  final port = ReceivePort();
  final count = parseInt(parser, parsed, "count")!;
  final isolates = parseInt(parser, parsed, "isolates", optional: true);
  if (isolates != null) {
    await Isolate.spawn<int>((int count) async {
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
    }, count ~/ isolates);
    return;
  }
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
