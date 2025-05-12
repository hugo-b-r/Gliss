import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<(String, String)> pickFirstFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    var name = "";
    var igcContent = "";
    for (var file in result.files) {
      name = file.name;
      igcContent = await file.xFile.readAsString();
    }
    return (igcContent, name);
  } else {
    // User canceled the picker
    throw 'User canceled the picker !';
  }

}



