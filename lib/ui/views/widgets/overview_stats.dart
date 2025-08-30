import 'package:flutter/material.dart';
import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:provider/provider.dart';

class OverviewStats extends StatelessWidget {
  const OverviewStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(builder: (ctx, map, _) => Builder(builder: (ctx) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
        Text("Altitude : ${map.getActualOverviewFix().gnssAlt.toStringAsFixed(0)} m"),
        Text("Vitesse : ${map.getActualOverviewFix().gsp.toStringAsFixed(0)} km/h"),
      ],);
    }));
  }
}
