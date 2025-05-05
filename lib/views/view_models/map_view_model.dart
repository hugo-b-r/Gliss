import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

import '../../data/igc_flight.dart';
import '../../data/files.dart';
import 'flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  String _loadedIgcFile = "";
  final List<FlightViewModel> flights = [];
  MapController? mapController = null;
  final double _initialZoom = 7;

  double get initialZoom => _initialZoom;

  void clearFlights() {
    flights.clear();
    notifyListeners();
  }

  List<Polyline> polylines() {
    List<Polyline> polylines = [];
    for (var flight in flights) {
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
    flights.add(flVm);

    if (mapController != null) {
      mapController!.move(flVm.boundaries.center, _initialZoom);
      mapController!.fitCamera(CameraFit.bounds(bounds: flVm.boundaries));
    }
    notifyListeners();
  }

  void updateFlightColor(String n, Color c) {
    print("entering color update loop");
    for (var f in flights) {
      if (f.name == n) {
        f.setColor(c);
      }
    }
    notifyListeners();
  }

  void mapNotifyListeners() {
    notifyListeners();
  }

  void centerOnFlight(String flight_name) {
    FlightViewModel? flight = null;
    for (var fl in flights) {
      if (fl.name == flight_name) {
        flight = fl;
      }
    }
    if (flight != null && mapController != null) {
      mapController!.move(flight.boundaries.center, _initialZoom);
      mapController!.fitCamera(CameraFit.bounds(bounds: flight.boundaries));
    }
  }

  void deleteFlight(String name) {
    flights.removeWhere((fl) => fl.name == name);
    notifyListeners();
  }
}
