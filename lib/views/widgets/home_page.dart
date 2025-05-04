import 'package:flutter/material.dart';
import 'package:gliding_aid/views/widgets/flight_list.dart';
import 'package:gliding_aid/views/widgets/flutter_map_opentopo_polyline.dart';
import 'package:provider/provider.dart';

import '../view_models/map_view_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // we need a layoutbuilder widget https://clouddevs.com/flutter/responsive-design/#:~:text=The%20LayoutBuilder%20widget%20gives%20you,adapt%20to%20different%20screen%20sizes.
    return Scaffold(
      body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth > 900) {
          return const HorizontalHomePage();
        } else {
          return const VerticalHomePage();
        }
      }),
    );
  }
}

class HorizontalHomePage extends StatefulWidget {
  const HorizontalHomePage({super.key});

  @override
  State<HorizontalHomePage> createState() => _HorizontalHomePageState();
}

class _HorizontalHomePageState extends State<HorizontalHomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
        builder: (context, map, _) => Row(
              children: [
                SizedBox(
                    width: 442.0,
                    child: ListView(children: <Widget>[
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await map.openIgcFile();
                            },
                            child: const Text("Ouvrir un fichier IGC"),
                          ),
                          IconButton(
                            iconSize: 24,
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              map.clearFlights();
                            },
                            alignment: Alignment.topRight,
                          ),
                        ],
                      ),
                      const FlightList(),
                    ])),
                const Expanded(child: FlutterMapOpentopoPolyline())
              ],
            ));
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
    return Consumer<MapViewModel>(
        builder: (context, map, _) => Column(
              children: [
                SizedBox(
                    height: 0.8 * height,
                    child: const Expanded(child: FlutterMapOpentopoPolyline())),
                Expanded(
                    child: ListView(children: <Widget>[
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await map.openIgcFile();
                        },
                        child: const Text("Ouvrir un fichier IGC"),
                      ),
                      IconButton(
                        iconSize: 24,
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          map.clearFlights();
                        },
                        alignment: Alignment.topRight,
                      ),
                    ],
                  ),
                  const FlightList(),
                ])),
              ],
            ));
  }
}
