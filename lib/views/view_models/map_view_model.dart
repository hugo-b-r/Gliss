import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/igc_flight.dart';
import '../../data/files.dart';
import 'flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  String _loadedIgcFile = "";
  final List<FlightViewModel> _flights = [];
  LatLngBounds? _boundaries;
  final MapController _mapController = MapController();
  final MapOptions _mapOptions = const MapOptions(keepAlive: false, initialZoom: 3.2, initialCenter: LatLng(50.0, 5.0));

  MapOptions get mapOptions => _mapOptions;

  MapController get mapController => mapController;

  void clearFlights() {
    _flights.clear();
  }

  List<Polyline> polylines() {
    List<Polyline> polylines = [];
    for (var flight in _flights) {
      polylines.add(flight.polyline);
    }
    return polylines;
  }

  Future<void> openIgcFile() async {
    try {
      _loadedIgcFile = await pickFirstFile();
    } catch (e) {
      throw Exception(e);
    }
    var currentFlight = Flight.create_from_file(_loadedIgcFile, FlightParsingConfig());
    Color randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
    var flVm = FlightViewModel(currentFlight, randomColor, 2);
    _flights.add(flVm);

    // _mapController.move(flVm.boundaries.center, _mapOptions.initialZoom);
    // _mapController.fitCamera(CameraFit.bounds(bounds: _boundaries!));

    print("Opened an IGC file");
    notifyListeners();
  }
}

