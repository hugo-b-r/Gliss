import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/igc_flight.dart';

class FlightViewModel {
  late Flight _flight;
  late Polyline _pl;
  late LatLngBounds _boundaries;

  FlightViewModel(Flight flight, Color color, double strokeWidth) {
    _flight = flight;
    _pl = _flight.to_polyline(strokeWidth, color);
    _boundaries = LatLngBounds.fromPoints(_flight.points());
  }

  Polyline get polyline => _pl;

  LatLngBounds get boundaries => _boundaries;

  void setColor(Color c) {
    var s = _pl.strokeWidth;
    _pl = _flight.to_polyline(s, c);
  }
}