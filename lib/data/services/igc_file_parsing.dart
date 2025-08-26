import 'package:file_picker/file_picker.dart';
import 'package:gliding_aid/utils/flight.dart';
import 'package:gliding_aid/utils/flight_parsing_config.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';
import 'package:gliding_aid/utils/utils.dart';

class IgcFileParser {

  String fileBuffer = "";
  String fileName = "";

  List<GNSSFix> fixes = [];
  List<String> aRecords = [];
  List<String> iRecords = [];
  List<String> hRecords = [];

  Flight? extractedFlight;

  Future pickFirstFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      var name = "";
      var igcContent = "";
      for (var file in result.files) {
        name = file.name;
        igcContent = await file.xFile.readAsString();
      }
      fileName = name;
      fileBuffer = igcContent;
    } else {
      // User canceled the picker
      throw 'User canceled the picker !';
    }

  }

  Flight parseFileBuffer(FlightParsingConfig config) {

    var fileLines = fileBuffer.multiSplit(["\n", "\r"]);
    for (var line in fileLines) {
      if (line.isNotEmpty) {
        if (line[0] == 'A') {
          aRecords.add(line);
        } else if (line[0] == 'B') {
          var fix = GNSSFix.buildFromBRecord(line, fixes.length);
          if (fixes.isEmpty ||
              (fix.rawtime - fixes[fixes.length - 1].rawtime).abs() > 1e-5) {
            // The time did change since the previous fix -> do not ignore it
            fixes.add(fix);
          }
        } else if (line[0] == 'I') {
          iRecords.add(line);
        } else if (line[0] == 'H') {
          hRecords.add(line);
        } else {
          // do not parse any other types of IGC records
        }
      }
    }
    extractedFlight = Flight(fixes, aRecords, hRecords, iRecords, config);
    return extractedFlight!;
  }
}