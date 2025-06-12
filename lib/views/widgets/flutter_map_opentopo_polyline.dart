import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:http_cache_drift_store/http_cache_drift_store.dart';

import '../view_models/map_view_model.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio/dio.dart';

class FlutterMapOpentopoPolyline extends StatefulWidget {
  final String? argPath;
  const FlutterMapOpentopoPolyline({super.key, this.argPath });


  @override
  State<FlutterMapOpentopoPolyline> createState() => _FlutterMapOpentopoPolylineState();
}

class _FlutterMapOpentopoPolylineState extends State<FlutterMapOpentopoPolyline> {


  @override
  Widget build(BuildContext context) {
    final mapController = MapController();
    var path = '';
    if (widget.argPath != null) {
      path = widget.argPath!;
    }
    final CacheStore _cacheStore = DriftCacheStore(
      databasePath: path, // ignored on web
      databaseName: 'DbCacheStore',
    );
    final _dio = Dio();
    return Consumer<MapViewModel>(

      builder : (context, map, _) => FlutterMap(

        mapController: mapController,
        options: MapOptions(keepAlive: true, initialZoom: 3.2, initialCenter: const LatLng(50.0, 5.0), onMapReady: () => {
          map.mapController = mapController
        }),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            //tileProvider: CachedTileProvider(store: HiveCacheStore(path, hiveBoxName: 'HiveCacheStore')),
            // CancellableNetworkTileProvider(),
            userAgentPackageName: 'com.gliding_aid.app',
            tileProvider: CachedTileProvider(
                dio: _dio,
                maxStale: const Duration(days: 30),
                store: _cacheStore,
                interceptors: [
                LogInterceptor(
                  logPrint: (object) => debugPrint(object.toString()),
                  responseHeader: false,
                  requestHeader: false,
                  request: false,
                )],
            ),//retinaMode: RetinaMode.isHighDensity(context),
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
