import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<(String, String)> pickFirstFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    var name = result.names[0];
    File file = File(result.files.single.path!);
    if (name == null) {
      name = "";
    }
    return (await file.readAsString(), name!);
  } else {
    // User canceled the picker
    throw 'User canceled the picker !';
  }

}



