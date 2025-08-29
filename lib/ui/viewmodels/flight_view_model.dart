import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/utils/flight.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';


class FlightViewModel extends ChangeNotifier {
  String name = "";
  late Flight _flight;
  late Polyline _pl;
  late LatLngBounds _boundaries;
  bool viewable = true;
  Color color = Colors.red;
  late GNSSFix overviewFix;

  FlightViewModel(Flight flight, Color c, double strokeWidth, String n) {
    _flight = flight;
    color = c;
    _pl = _flight.toPolyline(strokeWidth, color);
    _boundaries = LatLngBounds.fromPoints(_flight.points());
    name = n;
    overviewFix = flight.fixes()[0];
  }

  Polyline get polyline => _pl;

  Flight get flight => _flight;


  LatLngBounds get boundaries => _boundaries;

  void setColor(Color c) {
    color = c;
    var s = _pl.strokeWidth;
    _pl = _flight.toPolyline(s, color);
  }

  void toggleViewable() {
    viewable = !viewable;
    notifyListeners();
  }

  LineChartBarData toLineChartBarData() {
    List<FlSpot> spots = [];
    for (var fix in _flight.fixes()) {
      spots.add(FlSpot(fix.rawtime, fix.gnssAlt));
    }
    var lcb = LineChartBarData(
          isCurved: true,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
          spots: spots,
        );
    return lcb;
  }
}