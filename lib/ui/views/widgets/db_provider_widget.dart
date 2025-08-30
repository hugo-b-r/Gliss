import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_cache_drift_store/http_cache_drift_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class DbProviderWidget extends StatelessWidget {


  const DbProviderWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Provider<DriftCacheStore>(
        create: (context) => DriftCacheStore(
          databasePath: '', // ignored on web
          databaseName: 'DbCacheStore',
        ),
        child: child,
        dispose: (context, db) => db.close(),
      );
    } else {
      return FutureBuilder(
          future: getTemporaryDirectory(),
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              final dataPath = snapshot.requireData.path;
              return Provider<DriftCacheStore>(
                create: (context) => DriftCacheStore(
                  databasePath: dataPath,
                  databaseName: 'DbCacheStore',
                ),
                child: child,
                dispose: (context, db) => db.close(),
              );
            } else {
              return Text("Hello");
            }
          });
    }
  }
}
