import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

import '../../data/igc_flight.dart';
import '../../data/files.dart';
import 'flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  String _loadedIgcFile = "";
  final List<FlightViewModel> flights = [];
  LatLngBounds? _boundaries;
  final MapController? _mapController = null;
  double _initialZoom = 7;

  double get initialZoom => _initialZoom;

  MapController get mapController => mapController;
  void set_mapController(MapController mapController) {
    mapController = mapController;
  }

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
    var currentFlight = Flight.create_from_file(_loadedIgcFile, FlightParsingConfig());
    Color randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 1.0);
    var flVm = FlightViewModel(currentFlight, randomColor, 2, name);
    flights.add(flVm);

    if (_mapController != null) {
      _mapController.move(flVm.boundaries.center, _initialZoom);
      _mapController.fitCamera(CameraFit.bounds(bounds: _boundaries!));
    }
    notifyListeners();
  }

  void mapNotifyListeners() {
    notifyListeners();
  }
}

