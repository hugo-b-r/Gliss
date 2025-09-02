import 'package:file_picker/file_picker.dart';

Future<(String, String)> pickFirstFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

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

Future<List<(String, String)>> pickManyFiles() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

  if (result != null) {
    var name = "";
    var igcContent = "";
    List<(String, String)> res = [];
    for (var file in result.files) {
      name = file.name;
      igcContent = await file.xFile.readAsString();
      res.add((igcContent, name));
    }
    return res;
  } else {
    // User canceled the picker
    throw 'User canceled the picker !';
  }
}

