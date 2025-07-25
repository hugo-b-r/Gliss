import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gliding_aid/views/widgets/flight_list.dart';
import 'package:gliding_aid/views/widgets/menu_toolbar.dart';
import 'package:gliding_aid/views/widgets/flutter_map_opentopo_polyline.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../views/view_models/map_view_model.dart';
import '../views/widgets/chart.dart';

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
      body: Stack(
        // alignment: Alignment.center, // <---------
        children: [
          LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 900) {
              return const HorizontalHomePage();
            } else {
              return const VerticalHomePage();
            }
          }),
          Positioned(
              top: 10,
              right: 10,
              child: Container(
                height: 55,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(60)),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: const Offset(
                            5.0,
                            5.0,
                          ),
                          blurRadius: 10.0,
                          spreadRadius: 2.0,
                        ), //BoxShadow
                      ]),
                  child: const TopToolbar())),
        ],
      ),
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
    if (kIsWeb) {
      return const Row(
        children: [
          HomeMenu(ratio: 0.4),
          Expanded(child: FlutterMapOpentopoPolyline())
        ],
      );
    } else {
      return Row(
        children: [
          HomeMenu(ratio: 0.4),
          Expanded(
              child: FutureBuilder(
                  future: getTemporaryDirectory(),
                  builder: (ctx, snapshot) {
                    if (snapshot.hasData) {
                      final dataPath = snapshot.requireData.path;
                      return FlutterMapOpentopoPolyline(argPath: dataPath);
                    }
                    if (snapshot.hasError) {
                      debugPrint(snapshot.error.toString());
                      debugPrintStack(stackTrace: snapshot.stackTrace);
                      return Expanded(
                        child: Text(snapshot.error.toString()),
                      );
                    }
                    return Text("Hello");
                  }))
        ],
      );
    }
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
    if (kIsWeb) {
      return Column(children: [
        FlutterMapOpentopoPolyline(),
        Consumer<MapViewModel>(
            builder: (ctx, map, _) => Builder(builder: (ctx) {
                  if (map.flights.isNotEmpty) {
                    return SizedBox(
                        height: 0.4 * height,
                        child: HomeMenu(ratio: 0.2));
                  } else {
                    return SizedBox.shrink();
                  }
                }))
      ]);
    } else {
      return Consumer<MapViewModel>(
          builder: (context, map, _) => Column(
                children: [
                  Expanded(child: FutureBuilder(
                      future: getTemporaryDirectory(),
                      builder: (ctx, snapshot) {
                        if (snapshot.hasData) {
                          final dataPath = snapshot.requireData.path;
                          return FlutterMapOpentopoPolyline(
                              argPath: dataPath);
                        }
                        if (snapshot.hasError) {
                          debugPrint(snapshot.error.toString());
                          debugPrintStack(stackTrace: snapshot.stackTrace);
                          return Expanded(
                            child: Text(snapshot.error.toString()),
                          );
                        }
                        return Text("Hello");
                      })),
                  Consumer<MapViewModel>(
                      builder: (ctx, map, _) => Builder(builder: (ctx) {
                        if (map.flights.isNotEmpty) {
                          return SizedBox(
                              height: 0.4 * height,
                              child: HomeMenu(ratio: 0.2));
                        } else {
                          return SizedBox.shrink();
                        }
                      }))
                ],
              ));
    }
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
              value: progression,
              min: 0,
              max: 100,
              onChanged: (double value) {
                setState(() {
                  progression = value;
                });
              },
            ),
            SizedBox(height: widget.ratio * height, child: const FlightChart()),
          ]));
    }
  }
}
