import 'package:geobase/geobase.dart';

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