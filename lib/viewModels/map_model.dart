import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/files.dart';
import 'package:gliding_aid/igc_parsing.dart';
import 'package:latlong2/latlong.dart';

class MapModel extends ChangeNotifier {
  String _loadedIgcFile = "";
  Polyline? _polyline;
  LatLngBounds? _boundaries;
  MapOptions _mapOptions = const MapOptions(
      keepAlive: true, initialZoom: 3.2, initialCenter: LatLng(50.0, 5.0));

  Polyline? get polyline => _polyline;
  MapOptions get mapOptions => _mapOptions;

  Future<void> openIgcFile() async {
    try {
      _loadedIgcFile = await pick_first_file();
    } catch (e) {
      print(e);
    }
    Flight flight =
        Flight.createFromFile(_loadedIgcFile, FlightParsingConfig());
    _polyline = flight.toPolyline();
    if (polyline != null) {
      _boundaries = flight.toLatLngBounds();
      _mapOptions = MapOptions(
          keepAlive: true,
          initialCenter: _boundaries!.center,
          initialCameraFit: CameraFit.bounds(bounds: _boundaries!));
    }
    print("Will notify listeners in the near future !");
    notifyListeners();
    print("just did so !");
  }
}
