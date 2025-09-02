import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

import 'package:gliding_aid/data/files.dart';
import 'package:gliding_aid/ui/viewmodels/opentopo_distinguishable_palette.dart';
import 'package:gliding_aid/utils/flight.dart';
import 'package:gliding_aid/utils/flight_parsing_config.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';
import 'package:path/path.dart';
import '../../ui/viewmodels/flight_view_model.dart';

class MapViewModel with ChangeNotifier {
  final Map<String, FlightViewModel> flights = {};
  late List<String>? _filesToParse;
  MapController? mapController;
  final double _initialZoom = 7;
  String? selectedFlight;
  LineChartBarData? lineChartBarData;
  LineChartData? lineChartData;
  bool widgetReady =
      false; // to know whether we can use the mapcontroller or not
  int _flightProgressionIndex = 0;
  bool overviewVisibilty = false;

  MapViewModel({required List<String>? filesToParse}) {
    _filesToParse = filesToParse;
  }

  double get initialZoom => _initialZoom;

  int get flightProgressionIndex => _flightProgressionIndex;

  void clearFlights() {
    flights.clear();
    lineChartData = LineChartData();
    overviewVisibilty = false;
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

  Future<void> pickAndOpenIgcFile() async {
    List<(String, String)> contentName = [];

    try {
      contentName = await pickManyFiles();
    } catch (e) {
      throw Exception(e);
    }

    await openIgcFiles(contentName);
  }

  Future<void> openIgcFiles(List<(String, String)> contentName) async {

    FlightViewModel flightToFlightViewModelComputeFunc((String, String) contentName) {
      var currentFlight = Flight.createFromFile(contentName.$1, FlightParsingConfig());
      Color randomColor = openTopoDistinguishablePalette[math.Random().nextInt(openTopoDistinguishablePalette.length)];
      FlightViewModel flVm = FlightViewModel(currentFlight, randomColor, 3, contentName.$2);
      return flVm;
    }

    List<(String, Future<FlightViewModel>)> futFlightViewModels = [];
    for (var (content, name) in contentName) {
      futFlightViewModels.add((name, compute(flightToFlightViewModelComputeFunc as ComputeCallback<(String, String), FlightViewModel>, (content, name))));
    }

    for (var (name, fut) in futFlightViewModels) {
      flights[name] = await fut;
      notifyListeners();

    }
    //
    // if (flVm != null) {
    //   // we have opened a file so it should have been called once, right ?
    //   setCurrentChartData(flVm);
    //   if (widgetReady) {
    //     // we have opened a file so it should have been called once, right ?
    //     setCurrentChartData(flVm);
    //     mapController!.move(flVm.boundaries.center, _initialZoom);
    //     mapController!.fitCamera(CameraFit.bounds(bounds: flVm.boundaries));
    //   }
    // }
    //
    //
    // notifyListeners();
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
    overviewVisibilty = false;
    notifyListeners();
  }

  // to be moved to flutter_open_topo_map

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text('${value.toInt()}',
          style: TextStyle(
            color: Colors.black,
            fontSize: 12,
          )),
    );
  }

  void setCurrentChartData(FlightViewModel flight) {
    selectedFlight = flight.name;
    _flightProgressionIndex = flights[selectedFlight]!.overviewIndex;
    lineChartBarData = flight.toLineChartBarData();
    overviewVisibilty = true;
    lineChartData = LineChartData(
        lineBarsData: [lineChartBarData!],
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
    if (_filesToParse != null) {
      List<(String, String)> contentName = [];
      for (var filePath in _filesToParse!) {
        var file = File(filePath);
        if (file.existsSync()) {
          contentName.add((file.readAsStringSync(), basename(file.path)));
        }
      }
      openIgcFiles(contentName);
      _filesToParse = [];
    }
    widgetReady = true;
  }

  void isNotReady() {
    widgetReady = false;
  }

  void setFlightOverviewPoint(double progr) {
    flights[selectedFlight]!.overviewFixProgress = progr;
    var overviewFixIndex =
        (progr * flights[selectedFlight]!.flight.fixes().length / 100).toInt();
    flights[selectedFlight]!.overviewIndex = overviewFixIndex;
    flights[selectedFlight]!.overviewFix =
        flights[selectedFlight]!.flight.fixes()[overviewFixIndex];
    if (lineChartData != null) {
      lineChartData = lineChartData!.copyWith(lineBarsData: [
        lineChartBarData!.copyWith(showingIndicators: [overviewFixIndex])
      ]);
    }
    notifyListeners();
  }

  GNSSFix getActualOverviewFix() {
    if (flights[selectedFlight] == null) {
      return GNSSFix(0, 0, 0, "", 0, 0, "");
    } else {
      return flights[selectedFlight]!.overviewFix;
    }
  }

  Color getOverviewColor() {
    if (flights[selectedFlight] == null) {
      return Colors.black;
    } else {
      return flights[selectedFlight]!.color;
    }
  }

  double getOverviewProgress() {
    if (flights[selectedFlight] == null) {
      return 0;
    } else {
      return flights[selectedFlight]!.overviewFixProgress;
    }
  }
}
