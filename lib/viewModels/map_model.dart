import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/files.dart';
import 'package:gliding_aid/igc_parsing.dart';
import 'package:latlong2/latlong.dart';

class MapModel extends ChangeNotifier {
  String _loadedIgcFile = "";
  Polyline? polyline;
  LatLngBounds? _boundaries;
  MapOptions mapOptions =
      const MapOptions(initialZoom: 3.2, initialCenter: LatLng(50.0, 5.0));

  Future<void> openIgcFile() async {
    try {
      _loadedIgcFile = await pick_first_file();
    } catch (e) {
      print(e);
    }
    Flight flight =
        Flight.createFromFile(_loadedIgcFile, FlightParsingConfig());
    polyline = flight.toPolyline();
    if (polyline != null) {
      _boundaries = flight.toLatLngBounds();
      mapOptions = MapOptions(
          initialCenter: _boundaries!.center,
          initialCameraFit: CameraFit.bounds(bounds: _boundaries!));
    }
    notifyListeners();
  }
}
