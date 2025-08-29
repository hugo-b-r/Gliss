import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/utils/flight.dart';
import 'package:gliding_aid/utils/flight_parsing_config.dart';

class DisplayFlight {
  Flight flight = Flight([], [], [], [], FlightParsingConfig());
  Color color = Colors.black; // default color
  bool visible = true;

  DisplayFlight.fromFlight(Flight f) {
    flight = f;
  }

  Polyline toPolyline(double strokeWidth, Color lineColor) {
    return flight.toPolyline(strokeWidth, lineColor);
  }
}