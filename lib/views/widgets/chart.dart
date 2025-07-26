import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gliding_aid/views/view_models/map_view_model.dart';
import 'package:provider/provider.dart';

class FlightChart extends StatelessWidget {
  const FlightChart({super.key});

  @override
  Widget build(BuildContext context) {
    var map = Provider.of<MapViewModel>(context);

    //showing only if there is data to show
    if (map.lineChartData != null) {
      return Padding(
          padding: EdgeInsets.all(10.0),
          child: Consumer<MapViewModel>(
              builder: (context, map, _) => LineChart(map.lineChartData!)));
    } else {
      return const SizedBox.shrink();
    }
  }
}
