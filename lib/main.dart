import 'package:flutter/material.dart';
import 'package:gliding_aid/gliding_aid.dart';
import 'package:path_provider/path_provider.dart';


Future<String> getPath() async {
  final cacheDirectory = await getTemporaryDirectory();
  return cacheDirectory.path;
}

void main(List<String> arguments) {
  runApp(GlidingAid(arguments: arguments));
}
