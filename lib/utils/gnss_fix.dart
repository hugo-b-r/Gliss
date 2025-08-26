import 'package:geobase/geobase.dart';
import 'package:latlong2/latlong.dart';

import 'flight.dart';

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
