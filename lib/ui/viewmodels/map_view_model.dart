import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

import 'package:gliding_aid/data/files.dart';
import 'package:gliding_aid/utils/flight.dart';
import 'package:gliding_aid/utils/flight_parsing_config.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';
import '../../ui/viewmodels/flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  String _loadedIgcFile = "";
  final Map<String, FlightViewModel> flights = {};
  MapController? mapController;
  final double _initialZoom = 7;
  String? selectedFlight;
  LineChartData? lineChartData;
  bool widgetReady =
      false; // to know whether we can use the mapcontroller or not
  double _flightProgression = 0;


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
    String name = "";
    String file;
    try {
      (file, name) = await pickFirstFile();
      _loadedIgcFile = file;
    } catch (e) {
      throw Exception(e);
    }
    var currentFlight =
        Flight.createFromFile(_loadedIgcFile, FlightParsingConfig());
    Color randomColor = Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withValues(alpha: 1.0);
    var flVm = FlightViewModel(currentFlight, randomColor, 4, name);

    flights[name] = flVm;

    setCurrentChartData(flVm);

    if (widgetReady) {
      mapController!.move(flVm.boundaries.center, _initialZoom);
      mapController!.fitCamera(CameraFit.bounds(bounds: flVm.boundaries));
    }
    notifyListeners();
  }

  void updateFlightColor(String n, Color c) {
    flights[n]?.setColor(c);
    setCurrentChartData(flights[selectedFlight]!);
    notifyListeners();
  }

  void mapNotifyListeners() {
    notifyListeners();
  }

  void centerOnFlight(String flightName) {
    if (flights[flightName] != null && widgetReady) {
      mapController!.move(flights[flightName]!.boundaries.center, _initialZoom);
      mapController!
          .fitCamera(CameraFit.bounds(bounds: flights[flightName]!.boundaries));
    }
  }

  void deleteFlight(String name) {
    flights.remove(name);
    if (flights.isEmpty) {
      lineChartData = LineChartData();
    }
    notifyListeners();
  }

  // to be moved to flutter_open_topo_map

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}', style: TextStyle(
        color: Colors.black,
        fontSize: 12,
      )),
    );
  }

  void setCurrentChartData(FlightViewModel flight) {
    selectedFlight = flight.name;
    lineChartData = LineChartData(
        lineBarsData: [flight.toLineChartBarData()],
        lineTouchData: LineTouchData(handleBuiltInTouches: false),
        titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 500,
                reservedSize: 40,
                getTitlesWidget: leftTitleWidgets,
              ),
            )));
    notifyListeners();
  }

  void isReady() {
    widgetReady = true;
  }

  void isNotReady() {
    widgetReady = false;
  }

  void setFlightOverviewPoint(double progr) {
    _flightProgression = progr;
    var overviewFixIndex = ( progr * flights[selectedFlight]!.flight.fixes().length / 100).toInt();
    flights[selectedFlight]!.overviewFix = flights[selectedFlight]!.flight.fixes()[overviewFixIndex];
    notifyListeners();
    print(getActualOverviewFix().bearing * math.pi / 180);
  }

  GNSSFix getActualOverviewFix() {
    return flights[selectedFlight]!.overviewFix;
  }

  Color getOverviewColor() {
    return flights[selectedFlight]!.color;
  }
}
