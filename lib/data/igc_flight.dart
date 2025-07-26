/*
this is an igc parsing file
thanks to https://github.com/marcin-osowski/igc_lib for the help
 */


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geobase/geobase.dart';
import 'package:gliding_aid/utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

/// Filters a string removing non-printable characters.

/// Args:
///     string: A string to be filtered.

/// Returns:
///     A string, where non-printable characters are removed.
String _stripNonPrintableChars(String strNonStrip) {
  var clean = strNonStrip.replaceAll(RegExp(r'[^A-Za-z0-9().,;?]'), ' ');
  return clean;
}

class Turnpoint {
  Geographic pos = const Geographic(lon: 0, lat: 0);
  double radius = 0;
  String kind = "";

  Turnpoint(double lat, double lon, this.radius, this.kind) {
    pos = Geographic(lon: lon, lat: lat);
  }

  /// Checks wether a fix is in the turnpoint or not
  bool inRadius(Geographic fix) {
    double distance = fix.distanceTo2D(pos);
    return distance <= radius;
  }
}

class Task {
  List<Turnpoint> turnpoints = [];

  /// Raw time (seconds past midnight). The time after which pilots can start.
  int startTime = 0;

  /// Raw time (seconds past midnight). The time after which the race must have been finished.
  int endTime = 0;

  Task(this.turnpoints, this.startTime, this.endTime);

  /// Creates a task from a LK8000 task. Format seems to also be used by XCSoar.
  Task.createFromLktFile(String filecontent) {
    XmlDocument domTree = XmlDocument.parse(filecontent);

    // hwat if these tags are missing ?
    var taskpoints = domTree.findElements("taskpoints").first;
    var waypoints = domTree.findElements("waypoints").first;
    var gate = domTree.findElements("time-gate").first;
    List<XmlElement> tpoints = List.from(taskpoints.findElements("point"));
    List<XmlElement> wpoints = List.from(waypoints.findElements("point"));
    String startTimeHm = gate.getAttribute("open-time") ?? "00:00";

    List<String> stSp = startTimeHm.split(":");
    // concert start time from HH:MM to seconds
    var startTime = int.parse(stSp[0]) * 3600 + int.parse(stSp[0]) * 60;
    int endTime =
        24 * 3600 + 59 * 60 + 59; // default value for end time 23:59:59

    // Creates a dictionnary of names and a list of longitudes and latitudes
    Map<String, List<double>> coordinates = {};
    for (final point in wpoints) {
      String name = point.getAttribute("name") ?? "p";
      double longitude = double.parse(point.getAttribute("longitude") ?? "0");
      double latitude = double.parse(point.getAttribute("latitude") ?? "0");
      if (coordinates.containsKey(name)) {
        coordinates[name]?.add(longitude);
        coordinates[name]?.add(latitude);
      } else {
        coordinates[name] = [longitude, latitude];
      }
    }
    var kind = "";
    // Create a list of turnpoints
    for (final point in tpoints) {
      // get coordinates from wpoints
      var lat = (coordinates[point.getAttribute("name") ?? "p"] ?? [0, 0])[1];
      var lon = (coordinates[point.getAttribute("name") ?? "p"] ?? [0, 0])[0];
      double radius = double.parse(point.getAttribute("radius") ?? "0") / 1000;

      if (point == tpoints[0]) {
        // It is the start, the first turnpoint
        kind = ((point.getAttribute("Exit") ?? "false") == "true")
            ? "start_exit"
            : "start_enter";
      } else {
        if (point == tpoints[-1]) {
          // It is the last turnpoint
          kind = ((point.getAttribute("type") ?? "line") == "line")
              ? "goal_cylinder"
              : "goal_cylinder";
        } else {
          // All other turnpoints are cylinders
          kind = "cylinder";
        }
      }
      var turnpoint = Turnpoint(lat, lon, radius, kind);
      turnpoints.add(turnpoint);
    }
    turnpoints = turnpoints;
    startTime = startTime;
    endTime = endTime;
  }
}

class GNSSFix {
  /// Stores single GNSS flight recorder fix (a B-record).

  /// Raw attributes (i.e. attributes read directly from the B record):
  ///   rawtime: a float, time since last midnight, UTC, seconds
  ///   lat: a float, latitude in degrees
  ///   lon: a float, longitude in degrees
  ///   validity: a string, GPS validity information from flight recorder
  ///   pressAlt: a float, pressure altitude, meters
  ///   gnssAlt: a float, GNSS altitude, meters
  ///   extras: a string, B record extensions

  double rawtime = 0;
  double lat = 0;
  double lon = 0;
  String validity = "";
  double pressAlt = 0;
  double gnssAlt = 0;
  String extras = "";
  Flight? flight;

  /// Derived attributes:
  ///   index: an integer, the position of the fix in the IGC file
  ///   timestamp: a float, true timestamp (since epoch), UTC, seconds
  ///   alt: a float, either pressAlt or gnssAlt
  ///   gsp: a float, current ground speed, km/h
  ///   bearing: a float, aircraft bearing, in degrees
  ///   bearing_change_rate: a float, bearing change rate, degrees/second
  ///   flying: a bool, whether this fix is during a flight
  ///   circling: a bool, whether this fix is inside a thermal

  int index = 0;
  double timestamp = 0;
  double alt = 0.0;
  double gsp = 0;
  double bearing = 0;
  double bearingChangeRate = 0;
  bool flying = false;
  bool circling = false;

  GNSSFix(this.rawtime, this.lat, this.lon, this.validity,
      this.pressAlt, this.gnssAlt, this.extras) {
    flight = null;

    index = 0;
    timestamp = 0;
    alt = 0.0;
    gsp = 0;
    bearing = 0;
    bearingChangeRate = 0;
    flying = false;
    circling = false;
  }

  GNSSFix.buildFromBRecord(String bRrecordLine, int index) {
    var regexp = RegExp(
        r"^B(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d\d)([NS])(\d\d\d)(\d\d)(\d\d\d)([EW])([AV])([-\d]\d\d\d\d)([-\d]\d\d\d\d)([0-9a-zA-Z\-]*).*$");
    var match = regexp.firstMatch(bRrecordLine)!;
    //https://api.dart.dev/dart-core/Match/groups.html
    var hours = match.group(1)!;
    var minutes = match.group(2)!;
    var seconds = match.group(3)!;

    var latDeg = match.group(4)!;
    var latMin = match.group(5)!;
    var latMinDec = match.group(6)!;
    var latSign = match.group(7)!;

    var lonDeg = match.group(8)!;
    var lonMin = match.group(9)!;
    var lonMinDec = match.group(10)!;
    var lonSign = match.group(11)!;

    // var validity = match.group(12)!;
    var pressAltStr = match.group(13)!;
    var gnssAltStr = match.group(14)!;

    // var extras = match.group(15)!;

    rawtime = (double.parse(hours) * 60.0 + double.parse(minutes)) * 60.0 +
        double.parse(seconds);

    lat = double.parse(latDeg);
    lat += double.parse(latMin) / 60.0;
    lat += double.parse(latMinDec) / 1000.0 / 60.0;
    if (latSign == 'S') {
      lat = -lat;
    }

    lon = double.parse(lonDeg);
    lon += double.parse(lonMin) / 60.0;
    lon += double.parse(lonMinDec) / 1000.0 / 60.0;
    if (lonSign == 'W') {
      lon = -lon;
    }

    pressAlt = double.parse(pressAltStr);
    gnssAlt = double.parse(gnssAltStr);
  }

  /// Set parents flight object
  void setFlight(Flight flight) {
    this.flight = flight;
    if (this.flight?.altSource == "PRESS") {
      alt = pressAlt;
    } else if (this.flight?.altSource == "GNSS") {
      alt = gnssAlt;
    } else {
      throw 'WrongAltSourceType';
    }

    if (flight.dateTimestamp != null) {
      timestamp = rawtime + flight.dateTimestamp!;
    } else {
      timestamp = rawtime;
    }
  }

  /*String toString() {
    return ("GNSSFix(rawtime=%02d:%02d:%02d, lat=%f, lon=%f, pressAlt=%.1f, gnssAlt=%.1f)")
  }*/

  Geographic toGeographic() {
    return Geographic(lon: lon, lat: lat);
  }

  /// Computes bearing in degrees to another GNSSFix
  /// https://pub.dev/documentation/geobase/latest/geobase/EllipsoidalVincenty-class.html
  double bearingTo(GNSSFix other) {
    var geographic = toGeographic();
    // Creates a vincenty calculation object
    var vincenty = EllipsoidalVincenty(geographic);
    return vincenty.finalBearingTo(other.toGeographic());
  }

  /// computes distance to another fix
  double distanceTo(GNSSFix other) {
    var geographic = toGeographic();
    // Creates a vincenty calculation object
    var vincenty = EllipsoidalVincenty(geographic);
    return vincenty
        .inverse(other.toGeographic())
        .distance; // distance in meters
  }

  /// Reconstructs a B record
  String toBRecord() {
    var hours = rawtime / 3600;
    var minutes = (rawtime % 3600) / 60;
    var seconds = rawtime % 60;

    var latSign = "S";
    var lat = this.lat;
    if (this.lat < 0) {
      lat = -this.lat;
      latSign = 'S';
    } else {
      lat = -this.lat;
      latSign = 'N';
    }
    lat = (lat * 60000).roundToDouble();
    var latDeg = lat / 60000;
    var latMin = (lat % 60000) / 1000;
    var latMinDec = lat % 1000;

    var lonSign = "S";
    var lon = this.lon;
    if (this.lon < 0.0) {
      lon = -this.lon;
      lonSign = 'W';
    } else {
      lon = this.lon;
      lonSign = 'E';
    }

    lon = (lon * 60000).roundToDouble();
    var lonDeg = lon / 60000;
    var lonMin = (lon % 60000) / 1000;
    var lonMinDec = lon % 1000;

    var validity = this.validity;
    var pressAltInt = pressAlt.toInt();
    var gnssAltInt = gnssAlt.toInt();

    return 'B${hours.toString().padLeft(2, '0')}'
        '${minutes.toString().padLeft(2, '0')}${seconds.toString().padLeft(2, '0')}'
        '${latDeg.toString().padLeft(2, '0')}${latMin.toString().padLeft(2, '0')}'
        '${latMinDec.toString().padLeft(3, '0')}$latSign'
        '${lonDeg.toString().padLeft(2, '0')}${lonMin.toString().padLeft(2, '0')}'
        '${lonMinDec.toString().padLeft(3, '0')}$lonSign'
        '$validity'
        '${pressAltInt.toString().padLeft(5, '0')}${gnssAltInt.toString().padLeft(5, '0')}'
        '$extras';
  }

  LatLng toLatLng() {
    return LatLng(lat, lon);
  }
}

class Thermal {
  /// Represents a single thermal detected in flight.

  /// Attributes:
  ///  enter_fix: a GNSSFix, entry point of the thermal
  GNSSFix enterFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  GNSSFix exitFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");

  ///  exit_fix: a GNSSFix, exit_point of the thermal

  Thermal(GNSSFix enterFix, GNSSFix exitFix) {
    enterFix = enterFix;
    exitFix = exitFix;
  }

  /// Returns the time spent in the thermal in seconds
  double timeChange() {
    return exitFix.rawtime - enterFix.rawtime;
  }

  /// Retturns the altitude ained/lost in the thermal in meters
  double altChange() {
    return exitFix.alt - enterFix.alt;
  }

  /// Returns average velocity in the thermal in m/s
  double verticalVelocity() {
    if (timeChange().abs() < 1e-7) {
      return 0.0;
    }
    return altChange() / timeChange();
  }
}

class Glide {
  /// Represents a single glide detected in a flight
  ///
  /// Glides are portions of the recorded track between thermals
  ///
  /// Attributes:
  ///   enter_fix : a GNSSFix, entry poit of the glide
  ///   exit_fix : a GNSSFix, exit point of the glide
  ///   track_length : a double : the total length, in kilometers, of the recorded
  ///     track between the entry point and the exit point, note that this is not
  ///     the same as he distance between these points

  GNSSFix enterFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  GNSSFix exitFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  double trackLength = 0;

  Glide(GNSSFix enterFix, GNSSFix exitFix, double trackLength) {
    enterFix = enterFix;
    exitFix = exitFix;
    trackLength = trackLength;
  }

  /// Returns the time spent in the glide, seconds.
  double timeChange() {
    return exitFix.timestamp - enterFix.timestamp;
  }

  /// Returns the average speed in the glide, km/h.
  double speed() {
    return trackLength / (timeChange() / 3600);
  }

  /// Return the overall altitude change in the glide, meters.
  double altChange() {
    return exitFix.alt - enterFix.alt;
  }

  /// Returns the L/D of the glide.
  double glideRatio() {
    if (altChange().abs() < 1e-7) {
      return 0;
    }
    return trackLength * 1000 / altChange();
  }
}

class FlightParsingConfig extends Object {
  /// Configuration for parsing an IGC file.

  ///   Defines a set of parameters used to validate a file, and to detect
  ///   thermals and flight mode. Details in comments.

  // Flight validation parameters.
  // Minimum number of fixes in a file.
  var minFixes = 50;

  // Maximum time between fixes, seconds.
  // Soft limit, some fixes are allowed to exceed.
  var maxSecondsBetweenFixes = 50.0;

  // Minimum time between fixes, seconds.
  // Soft limit, some fixes are allowed to exceed.
  var miSecondsBetweenFixes = 1.0;

  // Maximum number of fixes exceeding time between fix constraints.
  var maxTimeViolations = 10;

  // Maximum number of times a file can cross the 0:00 UTC time.
  var maxNewDaysInFlight = 2;

  // Minimum average of absolute values of altitude changes in a file.
  // This is needed to discover altitude sensors (either pressure or
  // gps) that report either always constant altitude, or almost
  // always constant altitude, and therefore are invalid. The unit
  // is meters/fix.
  var minAvgAbsAltChange = 0.01;

  // Maximum altitude change per second between fixes, meters per second.
  // Soft limit, some fixes are allowed to exceed.
  var maxAltChangeRate = 50.0;

  // Maximum number of fixes that exceed the altitude change limit.
  var maxAltChangeViolations = 3;

  // Absolute maximum altitude, meters.
  var maxAlt = 10000.0;

  // Absolute minimum altitude, meters.
  var minAlt = -600.0;

  // Flight detection parameters.

  // Minimum ground speed to switch to flight mode, km/h.
  var minGspFlight = 15.0;

  // Minimum idle time (i.e. time with speed below min_gsp_flight) to switch
  // to landing, seconds. Exception: end of the file (tail fixes that
  // do not trigger the above condition), no limit is applied there.
  var minLandingTime = 5.0 * 60.0;

  // In case there are multiple continuous segments with ground
  // speed exceeding the limit, which one should be taken?
  // Available options:
  // - "first": take the first segment, ignore the part after
  // the first detected landing.
  // - "concat": concatenate all segments; will include the down
  // periods between segments (legacy behavior)
  var whichFlightToPick = "concat";

  // Thermal detection parameters.

  // Minimum bearing change to enter a thermal, deg/sec.
  var minBearingChangeCircling = 6.0;

  // Minimum time between fixes to calculate bearing change, seconds.
  // See the usage for a more detailed comment on why this is useful.
  var minTimeForBearingChange = 5.0;

  // Minimum time to consider circling a thermal, seconds.
  var minTimeForThermal = 60.0;
}

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

  /// Creates an instance of Flight from a given file.

  ///       Args:
  ///           filename: a string, the name of the input IGC file
  ///           config_class: a class that implements FlightParsingConfig

  ///       Returns:
  ///           An instance of Flight built from the supplied IGC file.
  static Flight createFromFile(String file, FlightParsingConfig config) {
    List<GNSSFix> fixes = [];
    List<String> aRecords = [];
    List<String> iRecords = [];
    List<String> hRecords = [];
    var fileLines = file.multiSplit(["\n", "\r"]);
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
    var flight = Flight(fixes, aRecords, hRecords, iRecords, config);
    return flight;
  }

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
    frManufCode = _stripNonPrintableChars(aRecords[0].substring(1, 4));
    frUniqId = _stripNonPrintableChars(aRecords[0].substring(4, 7));
  }

  /// Parses the IGC I records.

  ///       I records contain a description of extensions used in B records.
  void _parseIRecords(List<String> iRecords) {
    iRecord = _stripNonPrintableChars(iRecords.join(" "));
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
          date.add(_stripNonPrintableChars(group[0]!));
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
          gliderType = _stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFRFW" ||
        record.substring(0, 5) == "HFRHW") {
      var match = RegExp('HFR[FH]W[ ]*FIRMWARE[ ]*VERSION[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frFirmwareVersion = _stripNonPrintableChars(match1[0]!);
        }
      }

      // var match2 = RegExp('HFR[FH]W[ ]*HARDWARE[ ]*VERSION[ ]*:[ ]*(.*)',
      //    caseSensitive: false);
      if (match.hasMatch(record)) {
        var match3 = match.firstMatch(record);
        if (match3 != null) {
          frHardwareVersion = _stripNonPrintableChars(match3[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFFTY") {
      var match =
          RegExp('HFFTY[ ]*FR[ ]*TYPE[ ]*:[ ]*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frRecorderType = _stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFGPS") {
      var match = RegExp('HFGPS(?:[: ]|(?:GPS))*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frGpsReceiver = _stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFPRS") {
      var match = RegExp('HFPRS[ ]*PRESS[ ]*ALT[ ]*SENSOR[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          frPressureSensor = _stripNonPrintableChars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFCCL") {
      var match = RegExp('HFCCL[ ]*COMPETITION[ ]*CLASS[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          competitionClass = _stripNonPrintableChars(match1[0]!);
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
