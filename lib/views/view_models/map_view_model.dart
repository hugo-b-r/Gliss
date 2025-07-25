import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:gliding_aid/views/view_models/selected_point_marker.dart';

import '../../data/igc_flight.dart';
import '../../data/files.dart';
import 'flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  String _loadedIgcFile = "";
  final Map<String, FlightViewModel> flights = {};
  SelectedPointMarker? selectedPointMarker; // if null, not showed
  MapController? mapController;
  final double _initialZoom = 7;
  String? selectedFlight;
  LineChartData? lineChartData;

  double get initialZoom => _initialZoom;

  void clearFlights() {
    flights.clear();
    lineChartData = LineChartData();
    notifyListeners();
  }

  List<Polyline> polylines() {
    List<Polyline> polylines = [];
    for (var flight in flights.values) {
      if (flight.viewable == true) {
        polylines.add(flight.polyline);
      }
    }
    return polylines;
  }

  Future<void> openIgcFile() async {
    var name = "";
    var file;
    try {
      (file, name) = await pickFirstFile();
      _loadedIgcFile = file;
    } catch (e) {
      throw Exception(e);
    }
    var currentFlight =
        Flight.create_from_file(_loadedIgcFile, FlightParsingConfig());
    Color randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withValues(alpha: 1.0);
    var flVm = FlightViewModel(currentFlight, randomColor, 2, name);

    flights[name] = flVm;

    setCurrentChartData(flVm);

    if (mapController != null) {
      mapController!.move(flVm.boundaries.center, _initialZoom);
      mapController!.fitCamera(CameraFit.bounds(bounds: flVm.boundaries));
    }
    notifyListeners();
  }

  void updateFlightColor(String n, Color c) {
    flights[n]?.setColor(c);
    setCurrentChartData(flights[selectedFlight]);
    notifyListeners();
  }

  void mapNotifyListeners() {
    notifyListeners();
  }

  void centerOnFlight(String flightName) {
    if (flights[flightName] != null && mapController != null) {
      mapController!.move(flights[flightName]!.boundaries.center, _initialZoom);
      mapController!.fitCamera(CameraFit.bounds(bounds: flights[flightName]!.boundaries));
    }
  }

  void deleteFlight(String name) {
    flights.remove(name);
    if (flights.isEmpty) {
      lineChartData = LineChartData();
    }
    notifyListeners();
  }

  void setCurrentChartData(flight) {
    selectedFlight = flight.name;
    lineChartData = flight.lineChartData;
    notifyListeners();
  }
}
