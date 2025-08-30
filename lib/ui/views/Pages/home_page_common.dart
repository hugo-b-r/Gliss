
import 'package:flutter/material.dart';
import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:gliding_aid/ui/views/widgets/chart.dart';
import 'package:gliding_aid/ui/views/widgets/flight_list.dart';
import 'package:gliding_aid/ui/views/widgets/flutter_map_opentopo_polyline.dart';
import 'package:provider/provider.dart';

class HorizontalHomePage extends StatefulWidget {
  const HorizontalHomePage({super.key});

  @override
  State<HorizontalHomePage> createState() => _HorizontalHomePageState();
}

class _HorizontalHomePageState extends State<HorizontalHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        HomeMenu(ratio: 0.4),
        Expanded(child: FlutterMapOpentopoPolyline())
      ],
    );
  }
}

class VerticalHomePage extends StatefulWidget {
  const VerticalHomePage({super.key});

  @override
  State<VerticalHomePage> createState() => _VerticalHomePageState();
}

class _VerticalHomePageState extends State<VerticalHomePage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    return Column(children: [
      Expanded(child: FlutterMapOpentopoPolyline()),
      Consumer<MapViewModel>(
          builder: (ctx, map, _) => Builder(builder: (ctx) {
            if (map.flights.isNotEmpty) {
              return SizedBox(
                  height: 0.4 * height, child: HomeMenu(ratio: 0.2));
            } else {
              return SizedBox.shrink();
            }
          }))
    ]);
  }
}

class HomeMenu extends StatefulWidget {
  const HomeMenu({
    super.key,
    required this.ratio,
  });

  final double ratio;

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  double progression = 0;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.sizeOf(context).height;
    var map = Provider.of<MapViewModel>(context);
    if (map.flights.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return SizedBox(
          width: 442.0,
          child: Column(children: [
            const Expanded(child: SingleChildScrollView(child: FlightList())),
            Slider(
              value: map.getOverviewProgress(),
              min: 0,
              max: 100,
              onChanged: (double value) {
                setState(() {
                  progression = value;
                  map.setFlightOverviewPoint(value);
                });
              },
            ),
            SizedBox(height: widget.ratio * height, child: const FlightChart()),
          ]));
    }
  }
}
