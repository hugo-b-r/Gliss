import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/igc_flight.dart';

class FlightViewModel extends ChangeNotifier {
  String name = "";
  late Flight _flight;
  late Polyline _pl;
  late LatLngBounds _boundaries;
  bool viewable = true;
  Color color = Colors.red;

  FlightViewModel(Flight flight, Color c, double strokeWidth, String n) {
    _flight = flight;
    color = c;
    _pl = _flight.to_polyline(strokeWidth, color);
    _boundaries = LatLngBounds.fromPoints(_flight.points());
    name = n;
  }

  Polyline get polyline => _pl;

  LatLngBounds get boundaries => _boundaries;

  void setColor(Color c) {
    color = c;
    var s = _pl.strokeWidth;
    _pl = _flight.to_polyline(s, color);
  }

  void toggleViewable() {
    viewable = !viewable;
    notifyListeners();
  }
}