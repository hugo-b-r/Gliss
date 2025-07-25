/*
this is an igc parsing file
thanks to https://github.com/marcin-osowski/igc_lib for the help
 */


import 'package:fl_chart/fl_chart.dart';
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
String _strip_non_printable_chars(String strNonStrip) {
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
  bool in_radius(Geographic fix) {
    double distance = fix.distanceTo2D(pos);
    return distance <= radius;
  }
}

class Task {
  List<Turnpoint> turnpoints = [];

  /// Raw time (seconds past midnight). The time after which pilots can start.
  int start_time = 0;

  /// Raw time (seconds past midnight). The time after which the race must have been finished.
  int end_time = 0;

  Task(List<Turnpoint> turnpoints, int start_time, int end_time) {
    this.turnpoints = turnpoints;
    this.start_time = start_time;
    this.end_time = end_time;
  }

  /// Creates a task from a LK8000 task. Format seems to also be used by XCSoar.
  Task.create_from_lkt_file(String filecontent) {
    XmlDocument DOMTree = XmlDocument.parse(filecontent);

    // hwat if these tags are missing ?
    var taskpoints = DOMTree.findElements("taskpoints").first;
    var waypoints = DOMTree.findElements("waypoints").first;
    var gate = DOMTree.findElements("time-gate").first;
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
    start_time = startTime;
    end_time = endTime;
  }
}

class GNSSFix {
  /// Stores single GNSS flight recorder fix (a B-record).

  /// Raw attributes (i.e. attributes read directly from the B record):
  ///   rawtime: a float, time since last midnight, UTC, seconds
  ///   lat: a float, latitude in degrees
  ///   lon: a float, longitude in degrees
  ///   validity: a string, GPS validity information from flight recorder
  ///   press_alt: a float, pressure altitude, meters
  ///   gnss_alt: a float, GNSS altitude, meters
  ///   extras: a string, B record extensions

  double rawtime = 0;
  double lat = 0;
  double lon = 0;
  String validity = "";
  double press_alt = 0;
  double gnss_alt = 0;
  String extras = "";
  Flight? flight;

  /// Derived attributes:
  ///   index: an integer, the position of the fix in the IGC file
  ///   timestamp: a float, true timestamp (since epoch), UTC, seconds
  ///   alt: a float, either press_alt or gnss_alt
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
  double bearing_change_rate = 0;
  bool flying = false;
  bool circling = false;

  GNSSFix(double rawtime, double lat, double lon, String validity,
      double press_alt, double gnss_alt, String extras) {
    this.rawtime = rawtime;
    this.lat = lat;
    this.lon = lon;
    this.validity = validity;
    this.press_alt = press_alt;
    this.gnss_alt = gnss_alt;
    this.extras = extras;
    flight = null;

    index = 0;
    timestamp = 0;
    alt = 0.0;
    gsp = 0;
    bearing = 0;
    bearing_change_rate = 0;
    flying = false;
    circling = false;
  }

  GNSSFix.build_from_B_record(String B_record_line, int index) {
    var regexp = RegExp(
        r"^B(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d\d)([NS])(\d\d\d)(\d\d)(\d\d\d)([EW])([AV])([-\d]\d\d\d\d)([-\d]\d\d\d\d)([0-9a-zA-Z\-]*).*$");
    var match = regexp.firstMatch(B_record_line)!;
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
    var pressAlt = match.group(13)!;
    var gnssAlt = match.group(14)!;

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

    press_alt = double.parse(pressAlt);
    gnss_alt = double.parse(gnssAlt);
  }

  /// Set parents flight object
  void set_flight(Flight flight) {
    this.flight = flight;
    if (this.flight?.alt_source == "PRESS") {
      alt = press_alt;
    } else if (this.flight?.alt_source == "GNSS") {
      alt = gnss_alt;
    } else {
      throw 'WrongAltSourceType';
    }

    if (flight.date_timestamp != null) {
      timestamp = rawtime + flight.date_timestamp!;
    } else {
      timestamp = rawtime;
    }
  }

  /*String toString() {
    return ("GNSSFix(rawtime=%02d:%02d:%02d, lat=%f, lon=%f, press_alt=%.1f, gnss_alt=%.1f)")
  }*/

  Geographic to_geographic() {
    return Geographic(lon: lon, lat: lat);
  }

  /// Computes bearing in degrees to another GNSSFix
  /// https://pub.dev/documentation/geobase/latest/geobase/EllipsoidalVincenty-class.html
  double bearing_to(GNSSFix other) {
    var geographic = to_geographic();
    // Creates a vincenty calculation object
    var vincenty = EllipsoidalVincenty(geographic);
    return vincenty.finalBearingTo(other.to_geographic());
  }

  /// computes distance to another fix
  double distance_to(GNSSFix other) {
    var geographic = to_geographic();
    // Creates a vincenty calculation object
    var vincenty = EllipsoidalVincenty(geographic);
    return vincenty
        .inverse(other.to_geographic())
        .distance; // distance in meters
  }

  /// Reconstructs a B record
  String to_B_record() {
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
    var pressAlt = press_alt.toInt();
    var gnssAlt = gnss_alt.toInt();

    return 'B${hours.toString().padLeft(2, '0')}'
        '${minutes.toString().padLeft(2, '0')}${seconds.toString().padLeft(2, '0')}'
        '${latDeg.toString().padLeft(2, '0')}${latMin.toString().padLeft(2, '0')}'
        '${latMinDec.toString().padLeft(3, '0')}$latSign'
        '${lonDeg.toString().padLeft(2, '0')}${lonMin.toString().padLeft(2, '0')}'
        '${lonMinDec.toString().padLeft(3, '0')}$lonSign'
        '$validity'
        '${pressAlt.toString().padLeft(5, '0')}${gnssAlt.toString().padLeft(5, '0')}'
        '$extras';
  }

  LatLng to_lat_lng() {
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

  Thermal(GNSSFix enter_fix, GNSSFix exit_fix) {
    enterFix = enter_fix;
    exitFix = exit_fix;
  }

  /// Returns the time spent in the thermal in seconds
  double time_change() {
    return exitFix.rawtime - enterFix.rawtime;
  }

  /// Retturns the altitude ained/lost in the thermal in meters
  double alt_change() {
    return exitFix.alt - enterFix.alt;
  }

  /// Returns average velocity in the thermal in m/s
  double vertical_velocity() {
    if (time_change().abs() < 1e-7) {
      return 0.0;
    }
    return alt_change() / time_change();
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

  GNSSFix enter_fix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  GNSSFix exit_fix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  double track_length = 0;

  Glide(GNSSFix enter_fix, GNSSFix exit_fix, double track_length) {
    this.enter_fix = enter_fix;
    this.exit_fix = exit_fix;
    this.track_length = track_length;
  }

  /// Returns the time spent in the glide, seconds.
  double time_change() {
    return exit_fix.timestamp - enter_fix.timestamp;
  }

  /// Returns the average speed in the glide, km/h.
  double speed() {
    return track_length / (time_change() / 3600);
  }

  /// Return the overall altitude change in the glide, meters.
  double alt_change() {
    return exit_fix.alt - enter_fix.alt;
  }

  /// Returns the L/D of the glide.
  double glide_ratio() {
    if (alt_change().abs() < 1e-7) {
      return 0;
    }
    return track_length * 1000 / alt_change();
  }
}

class FlightParsingConfig extends Object {
  /// Configuration for parsing an IGC file.

  ///   Defines a set of parameters used to validate a file, and to detect
  ///   thermals and flight mode. Details in comments.

  // Flight validation parameters.
  // Minimum number of fixes in a file.
  var min_fixes = 50;

  // Maximum time between fixes, seconds.
  // Soft limit, some fixes are allowed to exceed.
  var max_seconds_between_fixes = 50.0;

  // Minimum time between fixes, seconds.
  // Soft limit, some fixes are allowed to exceed.
  var min_seconds_between_fixes = 1.0;

  // Maximum number of fixes exceeding time between fix constraints.
  var max_time_violations = 10;

  // Maximum number of times a file can cross the 0:00 UTC time.
  var max_new_days_in_flight = 2;

  // Minimum average of absolute values of altitude changes in a file.
  // This is needed to discover altitude sensors (either pressure or
  // gps) that report either always constant altitude, or almost
  // always constant altitude, and therefore are invalid. The unit
  // is meters/fix.
  var min_avg_abs_alt_change = 0.01;

  // Maximum altitude change per second between fixes, meters per second.
  // Soft limit, some fixes are allowed to exceed.
  var max_alt_change_rate = 50.0;

  // Maximum number of fixes that exceed the altitude change limit.
  var max_alt_change_violations = 3;

  // Absolute maximum altitude, meters.
  var max_alt = 10000.0;

  // Absolute minimum altitude, meters.
  var min_alt = -600.0;

  // Flight detection parameters.

  // Minimum ground speed to switch to flight mode, km/h.
  var min_gsp_flight = 15.0;

  // Minimum idle time (i.e. time with speed below min_gsp_flight) to switch
  // to landing, seconds. Exception: end of the file (tail fixes that
  // do not trigger the above condition), no limit is applied there.
  var min_landing_time = 5.0 * 60.0;

  // In case there are multiple continuous segments with ground
  // speed exceeding the limit, which one should be taken?
  // Available options:
  // - "first": take the first segment, ignore the part after
  // the first detected landing.
  // - "concat": concatenate all segments; will include the down
  // periods between segments (legacy behavior)
  var which_flight_to_pick = "concat";

  // Thermal detection parameters.

  // Minimum bearing change to enter a thermal, deg/sec.
  var min_bearing_change_circling = 6.0;

  // Minimum time between fixes to calculate bearing change, seconds.
  // See the usage for a more detailed comment on why this is useful.
  var min_time_for_bearing_change = 5.0;

  // Minimum time to consider circling a thermal, seconds.
  var min_time_for_thermal = 60.0;
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
  ///     press_alt_valid: a bool, whether the pressure altitude sensor is OK
  ///     gnss_alt_valid: a bool, whether the GNSS altitude sensor is OK

  bool valid = true;
  List<String> notes = [];
  List<GNSSFix> fixes = [];
  List<Thermal> thermals = [];
  List<Glide> glides = [];
  GNSSFix takeoff_fix = GNSSFix(0, 0, 0, "", 0, 0, "");
  GNSSFix landing_fix = GNSSFix(0, 0, 0, "", 0, 0, "");

  String glider_type = "";
  String competition_class = "";
  String fr_manuf_code = "";
  String fr_uniq_id = "";
  String i_record = "";
  String fr_firmware_version = "";
  String fr_hardware_version = "";
  String fr_recorder_type = "";
  String fr_gps_receiver = "";
  String fr_pressure_sensor = "";

  String alt_source = "";
  bool press_alt_valid = true;
  bool gnss_alt_valid = true;

  int? date_timestamp = 0;

  FlightParsingConfig _config = FlightParsingConfig();

  /// Creates an instance of Flight from a given file.

  ///       Args:
  ///           filename: a string, the name of the input IGC file
  ///           config_class: a class that implements FlightParsingConfig

  ///       Returns:
  ///           An instance of Flight built from the supplied IGC file.
  static Flight create_from_file(String file, FlightParsingConfig config) {
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
          var fix = GNSSFix.build_from_B_record(line, fixes.length);
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
  Flight(List<GNSSFix> fixes, List<String> a_records, List<String> h_records,
      List<String> i_records, FlightParsingConfig config) {
    _config = config;
    this.fixes = fixes;
    valid = true;
    notes = [];
    if (fixes.length < _config.min_fixes) {
      notes.add("Error : This file has ${fixes.length}, less than "
          "the minimum ${_config.min_fixes}");
      valid = false;
      return;
    }

    _check_altitudes();
    if (!valid) {
      return;
    }

    _check_fix_rawtime();
    if (!valid) {
      return;
    }

    if (press_alt_valid) {
      alt_source = "PRESS";
    } else if (gnss_alt_valid) {
      alt_source = "GNSS";
    } else {
      notes.add("Error : neither pressure nor gnss altitude is valid.");
      valid = false;
      return;
    }

    if (a_records.isNotEmpty) {
      _parse_a_records(a_records);
    }

    if (i_records.isNotEmpty) {
      _parse_i_records(i_records);
    }

    if (h_records.isNotEmpty) {
      _parse_h_records(h_records);
    }
  }

  /// Parses the IGC A record.

  ///       A record contains the flight recorder manufacturer ID and
  ///       device unique ID.
  void _parse_a_records(List<String> aRecords) {
    fr_manuf_code = _strip_non_printable_chars(aRecords[0].substring(1, 4));
    fr_uniq_id = _strip_non_printable_chars(aRecords[0].substring(4, 7));
  }

  /// Parses the IGC I records.

  ///       I records contain a description of extensions used in B records.
  void _parse_i_records(List<String> iRecords) {
    i_record = _strip_non_printable_chars(iRecords.join(" "));
  }

  /// Parses the IGC H records.

  ///       H records (header records) contain a lot of interesting metadata
  ///       about the file, such as the date of the flight, name of the pilot,
  ///       glider type, competition class, recorder accuracy and more.
  ///       Consult the IGC manual for details.
  void _parse_h_records(List<String> hRecords) {
    for (var record in hRecords) {
      _parse_h_record(record);
    }
  }

  void _parse_h_record(String record) {
    if (record.substring(0, 5) == "HFDTE") {
      var match = RegExp('(?:HFDTE|HFDTEDATE:[ ]*)(dd)(dd)(dd)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        List<String> date = [];
        for (var group in match.allMatches(record)) {
          date.add(_strip_non_printable_chars(group[0]!));
        }
        var year = int.parse(date[0]);
        var month = int.parse(date[1]);
        var day = int.parse(date[2]);
        if (1 <= month && month <= 12 && 1 <= day && day <= 31) {
          var date = DateTime.utc(year, month, day);
          date_timestamp = (date.millisecondsSinceEpoch / 1000).toInt();
        }
      }
    } else if (record.substring(0, 5) == "HFGTY") {
      var match =
          RegExp('HFGTY[ ]*GLIDER[ ]*TYPE[ ]*:[ ]*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          glider_type = _strip_non_printable_chars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFRFW" ||
        record.substring(0, 5) == "HFRHW") {
      var match = RegExp('HFR[FH]W[ ]*FIRMWARE[ ]*VERSION[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          fr_firmware_version = _strip_non_printable_chars(match1[0]!);
        }
      }

      // var match2 = RegExp('HFR[FH]W[ ]*HARDWARE[ ]*VERSION[ ]*:[ ]*(.*)',
      //    caseSensitive: false);
      if (match.hasMatch(record)) {
        var match3 = match.firstMatch(record);
        if (match3 != null) {
          fr_hardware_version = _strip_non_printable_chars(match3[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFFTY") {
      var match =
          RegExp('HFFTY[ ]*FR[ ]*TYPE[ ]*:[ ]*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          fr_recorder_type = _strip_non_printable_chars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFGPS") {
      var match = RegExp('HFGPS(?:[: ]|(?:GPS))*(.*)', caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          fr_gps_receiver = _strip_non_printable_chars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFPRS") {
      var match = RegExp('HFPRS[ ]*PRESS[ ]*ALT[ ]*SENSOR[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          fr_pressure_sensor = _strip_non_printable_chars(match1[0]!);
        }
      }
    } else if (record.substring(0, 5) == "HFCCL") {
      var match = RegExp('HFCCL[ ]*COMPETITION[ ]*CLASS[ ]*:[ ]*(.*)',
          caseSensitive: false);
      if (match.hasMatch(record)) {
        var match1 = match.firstMatch(record);
        if (match1 != null) {
          competition_class = _strip_non_printable_chars(match1[0]!);
        }
      }
    }
  }

  void _check_altitudes() {
    var pressAltViolationsNum = 0;
    var gnssAltViolationsNum = 0;
    var pressHugeChangesNum = 0;
    var gnssHugeChangesNum = 0;
    var pressChgsSum = 0.0;
    var gnssChgsSum = 0.0;

    for (var i = 0; i < fixes.length - 1; i++) {
      var pressAltDelta = (fixes[i + 1].press_alt - fixes[i].press_alt).abs();
      var gnssAltDelta = (fixes[i + 1].gnss_alt - fixes[i].gnss_alt).abs();
      var rawtimeDelta = (fixes[i + 1].rawtime - fixes[i].rawtime).abs();

      if (rawtimeDelta > 0.5) {
        if (pressAltDelta / rawtimeDelta > _config.max_alt_change_rate) {
          pressHugeChangesNum += 1;
        } else {
          pressChgsSum += pressAltDelta;
        }

        if (gnssAltDelta / rawtimeDelta > _config.max_alt_change_rate) {
          gnssHugeChangesNum += 1;
        } else {
          gnssChgsSum += gnssAltDelta;
        }
      }

      if ((fixes[i].press_alt > _config.max_alt) ||
          (fixes[i].press_alt > _config.min_alt)) {
        pressAltViolationsNum += 1;
      }
      if ((fixes[i].gnss_alt > _config.max_alt) ||
          (fixes[i].gnss_alt > _config.min_alt)) {
        gnssAltViolationsNum += 1;
      }
    }
    var pressChgsAvg = pressChgsSum / ((fixes.length - 1).roundToDouble());
    var gnssChgsAvg = gnssChgsSum / ((fixes.length - 1).roundToDouble());

    var pressAltOk = true;
    if (pressChgsAvg < _config.min_avg_abs_alt_change) {
      notes.add("Warning: average pressure altitude change between fixes "
          "is: $pressChgsAvg. It is lower than the minimum: ${_config.min_avg_abs_alt_change}.");
      pressAltOk = false;
    }

    if (pressHugeChangesNum > _config.max_alt_change_violations) {
      notes.add(
          "Warning: too many high changes in pressure altitude: $pressHugeChangesNum. "
          "Maximum allowed: ${_config.max_alt_change_violations}.");
      pressAltOk = false;
    }

    if (pressAltViolationsNum > 0) {
      notes.add(
          "Warning: pressure altitude limits exceeded in $pressAltViolationsNum fixes.");
      pressAltOk = false;
    }

    var gnssAltOk = true;
    if (gnssChgsAvg < _config.min_avg_abs_alt_change) {
      notes.add("Warning: average gnss altitude change between fixes "
          "is: $gnssChgsAvg. It is lower than the minimum: ${_config.min_avg_abs_alt_change}.");
      gnssAltOk = false;
    }

    if (gnssHugeChangesNum > _config.max_alt_change_violations) {
      notes.add(
          "Warning: too many high changes in gnss altitude: $gnssHugeChangesNum. "
          "Maximum allowed: ${_config.max_alt_change_violations}.");
      gnssAltOk = false;
    }

    if (gnssAltViolationsNum > 0) {
      notes.add(
          "Warning: gnss altitude limits exceeded in $gnssAltViolationsNum fixes.");
      gnssAltOk = false;
    }

    press_alt_valid = pressAltOk;
    gnss_alt_valid = gnssAltOk;
  }

  /// Checks for rawtime anomalies, fixes 0:00 UTC crossing.

  ///       The B records do not have fully qualified timestamps (just the current
  ///       time in UTC), therefore flights that cross 0:00 UTC need special
  ///       handling.
  void _check_fix_rawtime() {
    var DAY = 24.0 * 60.0 * 60.0;
    var rawtimeToAdd = 0.0;
    var rawtimeBetweenFixExceeded = 0;

    var daysAdded = 0;

    for (var i = 1; i < fixes.length; i++) {
      var f0 = fixes[i - 1];
      var f1 = fixes[i];
      f1.rawtime += rawtimeToAdd;

      if (f0.rawtime > f1.rawtime && f1.rawtime + DAY < f0.rawtime + 200.0) {
        // Day stitch
        daysAdded += 1;
        rawtimeToAdd += DAY;
        f1.rawtime += DAY;
      }

      var timeChange = f1.rawtime - f0.rawtime;

      if (timeChange < _config.min_seconds_between_fixes) {
        rawtimeBetweenFixExceeded += 1;
      }
      if (timeChange > _config.max_seconds_between_fixes) {
        rawtimeBetweenFixExceeded += 1;
      }
    }

    if (rawtimeBetweenFixExceeded > _config.max_time_violations) {
      notes.add("Error: too many fixes intervals exceed time between fixes "
          "constraints. Allowed ${_config.max_time_violations} fixes, found $rawtimeBetweenFixExceeded fixes.");
      valid = false;
    }

    if (daysAdded >= _config.max_new_days_in_flight) {
      notes.add("Error: too many times did the flight cross the UTC 0:00 "
          "barrier. Allowed ${_config.max_new_days_in_flight} times, found $daysAdded times.");
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

  Polyline toPpolyline(double strokeWidth, Color lineColor) {
    return Polyline(
        points: points(),
        color: lineColor,
        strokeWidth: strokeWidth,
      borderColor: Colors.white,
      borderStrokeWidth: 1,
    );
  }

  List<LatLng> points() {
    List<LatLng> points = [];
    for (var fix in fixes) {
      points.add(fix.to_lat_lng());
    }
    return points;
  }

  LineChartData toLineChartData(Color c) {
    List<FlSpot> spots = [];
    for (var fix in fixes) {
      spots.add(FlSpot(fix.rawtime, fix.gnss_alt));
    }
    var lc = LineChartData(
      lineBarsData: [LineChartBarData(
        isCurved: true,
        color: c,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),

      spots: spots,
      ),
    ]);
    return lc;
  }
}
