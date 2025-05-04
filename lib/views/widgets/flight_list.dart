
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/map_view_model.dart';

class FlightList extends StatefulWidget {
  const FlightList({super.key});

  @override
  State<FlightList> createState() => _FlightListState();
}

class _FlightListState extends State<FlightList> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    List<Widget> flights = [];
    var map = Provider.of<MapViewModel>(context);
    for (var flight in map.flights) {
      flights.add(CheckboxListTile(title: Text(flight.name), value: flight.viewable, onChanged:  (bool? value) {
        setState(() {
          flight.toggleViewable();
          map.mapNotifyListeners();
        });
      }));
    }
    return Column(children: flights);
  }
}