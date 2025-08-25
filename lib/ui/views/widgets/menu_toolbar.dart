import 'package:flutter/material.dart';
import 'package:gliding_aid/ui/views/Pages/settings_page.dart';
import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:provider/provider.dart';

import 'package:gliding_aid/l10n/app_localizations.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Consumer<MapViewModel>(
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
              IconButton(
                iconSize: 24,
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const SettingsPage();
                  }));
                },
                alignment: Alignment.topRight,
              ),
            ],
          ),
        ));
  }
}
