import 'package:flutter/material.dart';
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
            title: const Text('About'),
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
                                title: Text('About GlidingAid'),
                                content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // SizedBox(width: 200, child: Image(image: AssetImage('images/logo.png'))),
                                      Text(
                                          'This is a sample settings page for a Flutter application.'),
                                      Text('Version : ${settings.appVersion}'),
                                      Text(
                                          'Build number : ${settings.appBuildNumber}')
                                    ]),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Close'),
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
