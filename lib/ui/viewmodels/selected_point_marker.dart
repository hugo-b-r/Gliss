import 'package:latlong2/latlong.dart';

class SelectedPointMarker {
  LatLng center = LatLng(0, 0);
  double bearing = 0;

  SelectedPointMarker(LatLng c, double b) {
    center = c;
    bearing = b;
  }
}