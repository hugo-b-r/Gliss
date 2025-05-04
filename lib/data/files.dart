import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<String> pickFirstFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    File file = File(result.files.single.path!);
    return file.readAsString();
  } else {
    // User canceled the picker
    throw 'User canceled the picker !';
  }

}



