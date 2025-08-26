import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/utils/strip_non_printable_chars.dart';
import 'package:gliding_aid/utils/thermal.dart';
import 'package:latlong2/latlong.dart';

import 'flight_parsing_config.dart';
import 'glide.dart';
import 'gnss_fix.dart';

class Flight {
  /// Parses IGC file, detects thermals and checks for record anomalies.
  ///
  /// Before using an instance of Flight check the `valid` attribute. An
  /// invalid Flight instance is not usable. For an explaination why is
  /// a Flight invalid see the `notes` attribute.
  ///
  /// General attributes:
  ///     valid: a bool, whether the supplied record is considered valid
  ///     notes: a list of strings, warnings and errors encountered while
  ///     parsing/validating the file
  ///     fixes: a list of GNSSFix objects, one per each valid B record
  ///     thermals: a list of Thermal objects, the detected thermals
  ///     glides: a list of Glide objects, the glides between thermals
  ///     takeoff_fix: a GNSSFix object, the fix at which takeoff was detected
  ///     landing_fix: a GNSSFix object, the fix at which landing was detected
  ///
  /// IGC metadata attributes (some might be missing if the flight does not
  /// define them):
  ///     glider_type: a string, the declared glider type
  ///     competition_class: a string, the declared competition class
  ///     fr_manuf_code: a string, the flight recorder manufaturer code
  ///     fr_uniq_id: a string, the flight recorded unique id
  ///     i_record: a string, the I record (describing B record extensions)
  ///     fr_firmware_version: a string, the version of the recorder firmware
  ///     fr_hardware_version: a string, the version of the recorder hardware
  ///     fr_recorder_type: a string, the type of the recorder
  ///     fr_gps_receiver: a string, the used GPS receiver
  ///     fr_pressure_sensor: a string, the used pressure sensor
  ///
  /// Other attributes:
  ///     alt_source: a string, the chosen altitude sensor,
  ///     either "PRESS" or "GNSS"
  ///     pressAlt_valid: a bool, whether the pressure altitude sensor is OK
  ///     gnssAlt_valid: a bool, whether the GNSS altitude sensor is OK

  bool valid = true;
  bool visible = true;
  List<String> notes = [];
  List<GNSSFix> fixes = [];
  List<Thermal> thermals = [];
  List<Glide> glides = [];
  GNSSFix takeoffFix = GNSSFix(0, 0, 0, "", 0, 0, "");
  GNSSFix landingFix = GNSSFix(0, 0, 0, "", 0, 0, "");

  String gliderType = "";
  String competitionClass = "";
  String frManufCode = "";
  String frUniqId = "";
  String iRecord = "";
  String frFirmwareVersion = "";
  String frHardwareVersion = "";
  String frRecorderType = "";
  String frGpsReceiver = "";
  String frPressureSensor = "";

  String altSource = "";
  bool pressAltValid = true;
  bool gnssAltValid = true;

  int? dateTimestamp = 0;

  FlightParsingConfig _config = FlightParsingConfig();

  /// Initializer of the Flight class. Not meant to be directly used
  Flight(this.fixes, List<String> aRecords, List<String> hRecords,
      List<String> iRecords, FlightParsingConfig config) {
    _config = config;
    valid = true;
    notes = [];
    if (fixes.length < _config.minFixes) {
      notes.add("Error : This file has ${fixes.length}, less than "
          "the minimum ${_config.minFixes}");
      valid = false;
      return;
    }

    _checkAltitudes();
    if (!valid) {
      return;
    }

    _checkFixRawtime();
    if (!valid) {
      return;
    }

    if (pressAltValid) {
      altSource = "PRESS";
    } else if (gnssAltValid) {
      altSource = "GNSS";
    } else {
      notes.add("Error : neither pressure nor gnss altitude is valid.");
      valid = false;
      return;
    }

    if (aRecords.isNotEmpty) {
      _parseARecords(aRecords);
    }

    if (iRecords.isNotEmpty) {
      _parseIRecords(iRecords);
    }

    if (hRecords.isNotEmpty) {
      _parseHRecords(hRecords);
    }
  }

  /// Parses the IGC A record.

  ///       A record contains the flight recorder manufacturer ID and
  ///       device unique ID.
  void _parseARecords(List<String> aRecords) {
    frManufCode = stripNonPrintableChars(aRecords[0].substring(1, 4));
    frUniqId = stripNonPrintableChars(aRecords[0].substring(4, 7));
  }

  /// Parses the IGC I records.

  ///       I records contain a description of extensions used in B records.
  void _parseIRecords(List<String> iRecords) {
    iRecord = stripNonPrintableChars(iRecords.join(" "));
  }

  /// Parses the IGC H records.

  ///       H records (header records) contain a lot of interesting metadata
  ///       about the file, such as the date of the flight, name of the pilot,
  ///       glider type, competition class, recorder accuracy and more.
  ///       Consult the IGC manual for details.
  void _parseHRecords(List<String> hRecords) {
    for (var record in hRecords) {
      _parseHRecord(record);
    }
  }

  void _parseHRecord(String record) {
    if (record.substring(0, 5) == "HFDTE") {
      var match = RegExp('(?:HFDTE|HFDTEDATE:[ ]*)(dd)(dd)(dd)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        List<String> date = [];
        for (var group in match.allMatches(record)) {
          date.add(stripNonPrintableChars(group[0]!));
        }
        var year = int.parse(date[0]);
        var month = int.parse(date[1]);
        var day = int.parse(date[2]);
        if (1 <= month && month <= 12 && 1 <= day && day <= 31) {
          var date = DateTime.utc(year, month, day);
          dateTimestamp = (date.millisecondsSinceEpoch / 1000).toInt();
        }
      }
    } else if (record.substring(0, 5) == "HFGTY") {
      var match =
      RegExp('HFGTY[ ]*GLIDER[ ]*TYPE[ ]*:[ ]*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          gliderType = stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFRFW" ||
        record.substring(0, 5) == "HFRHW") {
      var match = RegExp('HFR[FH]W[ ]*FIRMWARE[ ]*VERSION[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frFirmwareVersion = stripNonPrintableChars(match1[0]!);
        }
      }

      // var match2 = RegExp('HFR[FH]W[ ]*HARDWARE[ ]*VERSION[ ]*:[ ]*(.*)',
      //    caseSensitive: false);
      if (match.hasMatch(record)) {
        var match3 = match.firstMatch(record);
        if (match3 != null) {
          frHardwareVersion = stripNonPrintableChars(match3[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFFTY") {
      var match =
      RegExp('HFFTY[ ]*FR[ ]*TYPE[ ]*:[ ]*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frRecorderType = stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFGPS") {
      var match = RegExp('HFGPS(?:[: ]|(?:GPS))*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frGpsReceiver = stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFPRS") {
      var match = RegExp('HFPRS[ ]*PRESS[ ]*ALT[ ]*SENSOR[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frPressureSensor = stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFCCL") {
      var match = RegExp('HFCCL[ ]*COMPETITION[ ]*CLASS[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          competitionClass = stripNonPrintableChars(match1[0]!);
        }
      }
    }
  }

  void _checkAltitudes() {
    var pressAltViolationsNum = 0;
    var gnssAltViolationsNum = 0;
    var pressHugeChangesNum = 0;
    var gnssHugeChangesNum = 0;
    var pressChgsSum = 0.0;
    var gnssChgsSum = 0.0;

    for (var i = 0; i < fixes.length - 1; i++) {
      var pressAltDelta = (fixes[i + 1].pressAlt - fixes[i].pressAlt).abs();
      var gnssAltDelta = (fixes[i + 1].gnssAlt - fixes[i].gnssAlt).abs();
      var rawtimeDelta = (fixes[i + 1].rawtime - fixes[i].rawtime).abs();

      if (rawtimeDelta > 0.5) {
        if (pressAltDelta / rawtimeDelta > _config.maxAltChangeRate) {
          pressHugeChangesNum += 1;
        } else {
          pressChgsSum += pressAltDelta;
        }

        if (gnssAltDelta / rawtimeDelta > _config.maxAltChangeRate) {
          gnssHugeChangesNum += 1;
        } else {
          gnssChgsSum += gnssAltDelta;
        }
      }

      if ((fixes[i].pressAlt > _config.maxAlt) ||
          (fixes[i].pressAlt > _config.minAlt)) {
        pressAltViolationsNum += 1;
      }
      if ((fixes[i].gnssAlt > _config.maxAlt) ||
          (fixes[i].gnssAlt > _config.minAlt)) {
        gnssAltViolationsNum += 1;
      }
    }
    var pressChgsAvg = pressChgsSum / ((fixes.length - 1).roundToDouble());
    var gnssChgsAvg = gnssChgsSum / ((fixes.length - 1).roundToDouble());

    var pressAltOk = true;
    if (pressChgsAvg < _config.minAvgAbsAltChange) {
      notes.add("Warning: average pressure altitude change between fixes "
          "is: $pressChgsAvg. It is lower than the minimum: ${_config.minAvgAbsAltChange}.");
      pressAltOk = false;
    }

    if (pressHugeChangesNum > _config.maxAltChangeViolations) {
      notes.add(
          "Warning: too many high changes in pressure altitude: $pressHugeChangesNum. "
              "Maximum allowed: ${_config.maxAltChangeViolations}.");
      pressAltOk = false;
    }

    if (pressAltViolationsNum > 0) {
      notes.add(
          "Warning: pressure altitude limits exceeded in $pressAltViolationsNum fixes.");
      pressAltOk = false;
    }

    var gnssAltOk = true;
    if (gnssChgsAvg < _config.minAvgAbsAltChange) {
      notes.add("Warning: average gnss altitude change between fixes "
          "is: $gnssChgsAvg. It is lower than the minimum: ${_config.minAvgAbsAltChange}.");
      gnssAltOk = false;
    }

    if (gnssHugeChangesNum > _config.maxAltChangeViolations) {
      notes.add(
          "Warning: too many high changes in gnss altitude: $gnssHugeChangesNum. "
              "Maximum allowed: ${_config.maxAltChangeViolations}.");
      gnssAltOk = false;
    }

    if (gnssAltViolationsNum > 0) {
      notes.add(
          "Warning: gnss altitude limits exceeded in $gnssAltViolationsNum fixes.");
      gnssAltOk = false;
    }

    pressAltValid = pressAltOk;
    gnssAltValid = gnssAltOk;
  }

  /// Checks for rawtime anomalies, fixes 0:00 UTC crossing.

  ///       The B records do not have fully qualified timestamps (just the current
  ///       time in UTC), therefore flights that cross 0:00 UTC need special
  ///       handling.
  void _checkFixRawtime() {
    var day = 24.0 * 60.0 * 60.0;
    var rawtimeToAdd = 0.0;
    var rawtimeBetweenFixExceeded = 0;

    var daysAdded = 0;

    for (var i = 1; i < fixes.length; i++) {
      var f0 = fixes[i - 1];
      var f1 = fixes[i];
      f1.rawtime += rawtimeToAdd;

      if (f0.rawtime > f1.rawtime && f1.rawtime + day < f0.rawtime + 200.0) {
        // Day stitch
        daysAdded += 1;
        rawtimeToAdd += day;
        f1.rawtime += day;
      }

      var timeChange = f1.rawtime - f0.rawtime;

      if (timeChange < _config.miSecondsBetweenFixes) {
        rawtimeBetweenFixExceeded += 1;
      }
      if (timeChange > _config.maxSecondsBetweenFixes) {
        rawtimeBetweenFixExceeded += 1;
      }
    }

    if (rawtimeBetweenFixExceeded > _config.maxTimeViolations) {
      notes.add("Error: too many fixes intervals exceed time between fixes "
          "constraints. Allowed ${_config.maxTimeViolations} fixes, found $rawtimeBetweenFixExceeded fixes.");
      valid = false;
    }

    if (daysAdded >= _config.maxNewDaysInFlight) {
      notes.add("Error: too many times did the flight cross the UTC 0:00 "
          "barrier. Allowed ${_config.maxNewDaysInFlight} times, found $daysAdded times.");
      valid = false;
    }
  }

  // /// Adds ground speed info (km/h) to self.fixes.
  // void _compute_ground_speeds() {
  //   fixes[0].gsp = 0.0;
  //   for (int i = 1; i < fixes.length; i++) {
  //     var dist = fixes[i].distance_to(fixes[i - 1]);
  //     var rawtime = fixes[i].rawtime - fixes[i - 1].rawtime;
  //     if (rawtime.abs() < 1e-5) {
  //       fixes[i].gsp = 0.0;
  //     } else {
  //       fixes[i].gsp = dist / rawtime * 3600;
  //     }
  //   }
  // }

  /// Generates raw flying/not flying emissions from ground speed.

  ///       Standing (i.e. not flying) is encoded as 0, flying is encoded as 1.
  ///       Exported to a separate function to be used in Baum-Welch parameters
  ///       learning.
  // List<int> _flying_emissions() {
  //   List<int> emissions = [];
  //   for (var fix in fixes) {
  //     if (fix.gsp > _config.min_gsp_flight) {
  //       emissions.add(1);
  //     } else {
  //       emissions.add(0);
  //     }
  //   }
  //   return emissions;
  // }

//   /// Adds boolean flag .flying to self.fixes.

//   ///       Two pass:
//   ///         1. Viterbi decoder
//   ///         2. Only emit landings (0) if the downtime is more than
//   ///            _config.min_landing_time (or it's the end of the log).
//   void _compute_flight() {
//     var emissions = this._flying_emissions();

//   }
// }

  Polyline toPolyline(double strokeWidth, Color lineColor) {
    return Polyline(
      points: points(),
      color: lineColor,
      strokeWidth: strokeWidth,
      borderColor: Colors.white,
      borderStrokeWidth: 2,
    );
  }

  List<LatLng> points() {
    List<LatLng> points = [];
    for (var fix in fixes) {
      points.add(fix.toLatLng());
    }
    return points;
  }
}