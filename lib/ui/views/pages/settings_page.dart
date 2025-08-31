import 'package:flutter/material.dart';
import 'package:gliding_aid/l10n/app_localizations.dart';
import 'package:gliding_aid/ui/viewmodels/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context)!.about),
            onTap: () {
              // Navigate to About Page or show a dialog
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Consumer<SettingsViewModel>(
                        builder: (context, settings, _) {
                      return FutureBuilder(
                          future: settings.updatePackageInfoIfNeeded(),
                          builder: (ctx, snapshot) {
                            if (snapshot.hasData && snapshot.requireData) {
                              return AlertDialog(
                                icon: SizedBox(
                                    width: 20,
                                    child: Image(
                                        image: AssetImage('images/logo.png'))),
                                title: Text(
                                    '${AppLocalizations.of(context)!.aboutTitle}'),
                                content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // SizedBox(width: 200, child: Image(image: AssetImage('images/logo.png'))),
                                      Text(AppLocalizations.of(context)!
                                          .aboutDesc),
                                      Text(
                                          '${AppLocalizations.of(context)!.version} : ${settings.appVersion}'),
                                      Text(
                                          '${AppLocalizations.of(context)!.buildNumber} : ${settings.appBuildNumber}')
                                    ]),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                        AppLocalizations.of(context)!.close),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          });
                    });
                  });
            },
          ),
        ],
      ),
    );
  }
}
