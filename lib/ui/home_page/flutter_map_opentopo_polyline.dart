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
      return MapPolyline(mapOptions: mapOptions, polyline: polyline);
    } else {
      return MapNoPolyline(mapOptions: mapOptions);
    }
  }
}

class MapNoPolyline extends StatelessWidget {
  const MapNoPolyline({
    super.key,
    required this.mapOptions,
  });

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

class MapPolyline extends StatelessWidget {
  const MapPolyline({
    super.key,
    required this.mapOptions,
    required this.polyline,
  });

  final MapOptions mapOptions;
  final Polyline polyline;

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
