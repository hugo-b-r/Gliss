import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:http_cache_drift_store/http_cache_drift_store.dart';

import '../../Pages/settings_page.dart';
import '../view_models/map_view_model.dart';
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
    final mapController = MapController();
    var path = '';
    if (widget.argPath != null) {
      path = widget.argPath!;
    }
    final CacheStore cacheStore = DriftCacheStore(
      databasePath: path, // ignored on web
      databaseName: 'DbCacheStore',
    );
    final dio = Dio();
    return Stack(
      children: [
        Consumer<MapViewModel>(
            builder: (context, map, _) => FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                      keepAlive: true,
                      initialZoom: 3.2,
                      initialCenter: const LatLng(50.0, 5.0),
                      onMapReady: () => {map.mapController = mapController}),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://b.tile.opentopomap.org/{z}/{x}/{y}.png',
                      //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
                      // CancellableNetworkTileProvider(),
                      userAgentPackageName: 'com.gliding_aid.app',
                      tileProvider: CachedTileProvider(
                        dio: dio,
                        maxStale: const Duration(days: 30),
                        store: cacheStore,
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
                    const RichAttributionWidget(
                        animationConfig: ScaleRAWA(),
                        attributions: [
                          TextSourceAttribution(
                              'Map data: © OpenStreetMap-Mitwirkende, SRTM | Map display: © OpenTopoMap (CC-BY-SA)')
                        ]),
                  ],
                )),
        Positioned(
            top: 20,
            right: 20,
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  iconSize: 30,
                  icon:
                      const Icon(Icons.settings_outlined, opticalSize: 48, weight: 400),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) {
                      return const SettingsPage();
                    }));
                  },
                  alignment: Alignment.topLeft,
                ))),
      ],
    );
  }
}
