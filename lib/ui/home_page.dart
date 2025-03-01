import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:gliding_aid/viewModels/map_model.dart';
import 'package:provider/provider.dart';

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
  MapModel map = MapModel();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // we need a layoutbuilder widget https://clouddevs.com/flutter/responsive-design/#:~:text=The%20LayoutBuilder%20widget%20gives%20you,adapt%20to%20different%20screen%20sizes.
    map = context.watch<MapModel>();
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

class HorizontalHomePage extends StatelessWidget {
  const HorizontalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    MapModel map = context.watch<MapModel>();
    Widget w = const Text("we don't care about this actually");
    if (map.polyline != null) {
      w = Row(
        children: [
          SizedBox(
              width: 442.0,
              child: Wrap(spacing: 18.0, children: <Widget>[
                UnconstrainedBox(
                    child: ElevatedButton(
                  onPressed: () async {
                    await map.openIgcFile();
                  },
                  child: const Text("Ouvrir un fichier IGC"),
                )),
              ])),
          Expanded(child: Consumer<MapModel>(
            builder: (context, map, child) {
              return FlutterMapOpentopoPolyline(
                polyline: map.polyline!,
                mapOptions: map.mapOptions,
              );
            },
          ))
        ],
      );
    } else {
      w = Row(
        children: [
          SizedBox(
              width: 442.0,
              child: Wrap(spacing: 18.0, children: <Widget>[
                UnconstrainedBox(
                    child: ElevatedButton(
                  onPressed: () async {
                    await map.openIgcFile();
                  },
                  child: const Text("Ouvrir un fichier IGC"),
                )),
              ])),
          Expanded(child: Consumer<MapModel>(
            builder: (context, map, child) {
              return FlutterMapOpentopo(
                mapOptions: map.mapOptions,
              );
            },
          ))
        ],
      );
    }
    return Consumer<MapModel>(
      builder: (context, map, child) {
        return w;
      },
    );
  }
}

class VerticalHomePage extends StatelessWidget {
  const VerticalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    MapModel map = context.watch<MapModel>();
    double height = MediaQuery.sizeOf(context).height;
    Widget w = const Text("We don't care about this one");
    if (map.polyline != null) {
      w = Column(
        children: [
          SizedBox(
              height: 0.8 * height,
              child: Expanded(child: Consumer<MapModel>(
                builder: (context, map, child) {
                  return FlutterMapOpentopoPolyline(
                    polyline: map.polyline!,
                    mapOptions: map.mapOptions,
                  );
                },
              ))),
          Expanded(
              child: ElevatedButton(
            onPressed: () async {
              await map.openIgcFile();
            },
            child: const Text("Ouvrir un fichier IGC"),
          )),
        ],
      );
    } else {
      w = Column(
        children: [
          SizedBox(
            height: 0.8 * height,
            child: Expanded(child: Consumer<MapModel>(
              builder: (context, map, child) {
                return FlutterMapOpentopo(
                  mapOptions: map.mapOptions,
                );
              },
            )),
          ),
          Expanded(
              child: ElevatedButton(
            onPressed: () async {
              await map.openIgcFile();
            },
            child: const Text("Ouvrir un fichier IGC"),
          )),
        ],
      );
    }
    return w;
  }
}

class FlutterMapOpentopo extends StatelessWidget {
  const FlutterMapOpentopo({super.key, required this.mapOptions});

  final MapOptions mapOptions;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      children: [
        TileLayer(
          urlTemplate: 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
          //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
          userAgentPackageName: 'com.gliding_aid.app',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        const RichAttributionWidget(
            animationConfig: ScaleRAWA(),
            attributions: [
              TextSourceAttribution(
                  'Map data: © OpenStreetMap-Mitwirkende, SRTM | Map display: © OpenTopoMap (CC-BY-SA)')
            ]),
      ],
    );
  }
}

class FlutterMapOpentopoPolyline extends StatelessWidget {
  const FlutterMapOpentopoPolyline(
      {super.key, required this.polyline, required this.mapOptions});

  final Polyline<Object> polyline;
  final MapOptions mapOptions;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: mapOptions,
      children: [
        TileLayer(
          urlTemplate: 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
          //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
          userAgentPackageName: 'com.gliding_aid.app',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        PolylineLayer(
          polylines: [polyline],
        ),
        const RichAttributionWidget(
            animationConfig: ScaleRAWA(),
            attributions: [
              TextSourceAttribution(
                  'Map data: © OpenStreetMap-Mitwirkende, SRTM | Map display: © OpenTopoMap (CC-BY-SA)')
            ]),
      ],
    );
  }
}
