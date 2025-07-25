import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:gliding_aid/viewModels/map_model.dart';
import 'package:provider/provider.dart';

class FlutterMapOpentopoPolyline extends StatelessWidget {
  const FlutterMapOpentopoPolyline({super.key, required this.mapOptions});

  final MapOptions mapOptions;

  @override
  Widget build(BuildContext context) {
    MapModel map = context.watch<MapModel>();
    Polyline? polyline = map.polyline;
    if (polyline != null) {
      return MapPolyline();
    } else {
      return MapNoPolyline();
    }
  }
}

class MapNoPolyline extends StatefulWidget {
  MapNoPolyline({super.key});

  @override
  State<MapNoPolyline> createState() => _MapNoPolylineState();
}

class _MapNoPolylineState extends State<MapNoPolyline> {
  @override
  Widget build(BuildContext context) {
    MapModel map = Provider.of<MapModel>(context);
    return FlutterMap(
      options: map.mapOptions,
      mapController: map.mapController,
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

class MapPolyline extends StatefulWidget {
  MapPolyline({
    super.key,
  });

  @override
  State<MapPolyline> createState() => _MapPolylineState();
}

class _MapPolylineState extends State<MapPolyline> {
  @override
  Widget build(BuildContext context) {
    MapModel map = Provider.of<MapModel>(context);
    return FlutterMap(
      options: map.mapOptions,
      mapController: map.mapController,
      children: [
        TileLayer(
          urlTemplate: 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
          //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
          userAgentPackageName: 'com.gliding_aid.app',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        PolylineLayer(
          polylines: [
            map.polyline!
          ], // We are sure the polyline is not null as tested before running this widget
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
