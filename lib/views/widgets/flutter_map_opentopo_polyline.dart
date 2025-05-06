import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../view_models/map_view_model.dart';

class FlutterMapOpentopoPolyline extends StatefulWidget {
  const FlutterMapOpentopoPolyline({super.key});


  @override
  State<FlutterMapOpentopoPolyline> createState() => _FlutterMapOpentopoPolylineState();
}

class _FlutterMapOpentopoPolylineState extends State<FlutterMapOpentopoPolyline> {
  final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(

      builder : (context, map, _) => FlutterMap(

        mapController: mapController,
        options: MapOptions(keepAlive: true, initialZoom: 3.2, initialCenter: const LatLng(50.0, 5.0), onMapReady: () => {
          map.mapController = mapController
        }),
        children: [
          TileLayer(
            urlTemplate: 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
            //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
            // CancellableNetworkTileProvider(),
            userAgentPackageName: 'com.gliding_aid.app',
            tileProvider: CancellableNetworkTileProvider(),
            retinaMode: RetinaMode.isHighDensity(context),
          ),
          PolylineLayer(
            polylines: map.polylines(),
          ),
          const RichAttributionWidget(animationConfig: ScaleRAWA(), attributions: [
            TextSourceAttribution(
                'Map data: © OpenStreetMap-Mitwirkende, SRTM | Map display: © OpenTopoMap (CC-BY-SA)')
          ]),
        ],
      )
    );
  }
}
