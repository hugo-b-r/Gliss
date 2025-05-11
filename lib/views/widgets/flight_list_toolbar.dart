import 'package:flutter/material.dart';
import 'package:gliding_aid/views/view_models/map_view_model.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';

class FlightListToolbar extends StatelessWidget {
  const FlightListToolbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(10.0), child: Consumer<MapViewModel>(
      builder: (context, map, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () async {
              await map.openIgcFile();
            },
            child: Text(AppLocalizations.of(context)!.openFlight),
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
    ));
  }
}
