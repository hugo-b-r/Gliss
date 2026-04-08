import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/ui/views/widgets/oriented_plane_marker.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:http_cache_drift_store/http_cache_drift_store.dart';

import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio/dio.dart';

class FlutterMapOpentopoPolyline extends StatefulWidget {
  final String? argPath;
  const FlutterMapOpentopoPolyline({super.key, this.argPath});

  @override
  State<FlutterMapOpentopoPolyline> createState() =>
      _FlutterMapOpentopoPolylineState();
}

class _FlutterMapOpentopoPolylineState
    extends State<FlutterMapOpentopoPolyline> {
  @override
  Widget build(BuildContext context) {
    var map = Provider.of<MapViewModel>(context);
    if (map.mapController == null) {
      map.mapController = MapController();
      map.isNotReady();
    }

    final dio = Dio();
    return Consumer<MapViewModel>(
        builder: (context, map, _) => FlutterMap(
              mapController: map.mapController,
              options: MapOptions(
                  keepAlive: true,
                  initialZoom: 3.2,
                  initialCenter: const LatLng(50.0, 5.0),
                  interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.pinchMove),
                  onMapReady: () => {map.isReady()}),
              children: [
                TileLayer(
                  urlTemplate: 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
                  //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
                  // CancellableNetworkTileProvider(),
                  userAgentPackageName: 'com.gliding_aid.app',
                  tileProvider: CachedTileProvider(
                    dio: dio,
                    maxStale: const Duration(days: 30),
                    store: Provider.of<DriftCacheStore>(context),
                    interceptors: [
                      LogInterceptor(
                        logPrint: (object) => debugPrint(object.toString()),
                        responseHeader: false,
                        requestHeader: false,
                        request: false,
                      )
                    ],
                  ), //retinaMode: RetinaMode.isHighDensity(context),
                ),
                PolylineLayer(
                  polylines: map.polylines(),
                ),
                OrientedPlaneMarker(),
                const RichAttributionWidget(
                    animationConfig: ScaleRAWA(),
                    attributions: [
                      TextSourceAttribution(
                          'Map data: © OpenStreetMap-Mitwirkende, SRTM | Map display: © OpenTopoMap (CC-BY-SA)')
                    ]),
              ],
            ));
  }
}
