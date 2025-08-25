import 'package:flutter/material.dart';
import 'package:gliding_aid/data/color_picking.dart';
import 'package:provider/provider.dart';

import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';

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
    for (var flight in map.flights.values) {
      flights.add(ListTile(
        title: Text(flight.name),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: () => {
                map.centerOnFlight(flight.name),
                map.setCurrentChartData(flight)
              },
              icon: const Icon(Icons.my_location)),
          IconButton(
              onPressed: () => map.setCurrentChartData(flight),
              icon: const Icon(Icons.query_stats)),
          IconButton(
              color: flight.color,
              onPressed: () async {
                var color = await pickColor(context, flight);
                map.updateFlightColor(flight.name, color);
              },
              icon: const Icon(Icons.palette)),
          Checkbox(
              value: flight.viewable,
              onChanged: (bool? value) {
                setState(() {
                  flight.toggleViewable();
                  map.mapNotifyListeners();
                });
              }),
        ]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () => map.deleteFlight(flight.name),
                icon: const Icon(Icons.close))
          ],
        ),
      ));
    }
    return Column(children: flights);
  }
}
// Il faut créer une tile custom, ajouter un icon button avec l'icone "palette" pour le color picker, une croix pour supprimer le vol de la liste
