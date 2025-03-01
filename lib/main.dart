import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gliding_aid/gliding_aid.dart';

Future<String> getPath() async {
  final cacheDirectory = await getTemporaryDirectory();
  return cacheDirectory.path;
}

void main() {
  runApp(const GlidingAid());
}
