import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/data/repositories/display_flight.dart';
import 'package:gliding_aid/data/services/igc_file_parsing.dart';
import 'package:gliding_aid/utils/flight_parsing_config.dart';

class FlightsRepository {
  final Map<String, DisplayFlight> _flights = {};

  List<Polyline> getAsPolylines() {
    List<Polyline> polylines = [];
    for (var flight in _flights.values) {
      if (flight.visible == true) {
        Color randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
            .withValues(alpha: 1.0);
        polylines.add(flight.toPolyline(4, randomColor));
      }
    }
    return polylines;
  }

  void pickNewFile() async {
    String name = "";
    String file;
    IgcFileParser p = IgcFileParser();
    try {
      await p.pickFirstFile();
    } catch (e) {
      throw Exception(e);
    }
    _flights[name] = DisplayFlight.fromFlight(p.parseFileBuffer(FlightParsingConfig()));
  }

  void updateFlightColor(String n, Color c) {
    // _flights[n]?.setColor(c);
    // setCurrentChartData(flights[selectedFlight]!);
    // notifyListeners();
  }

  void deleteFlight(String name) {
    _flights.remove(name);
    // if (_flights.isEmpty) {
    //   lineChartData = LineChartData();
    // }
  }

  List<DisplayFlight> getFlights() {
    return _flights.values.toList();
  }
}