import 'package:flutter/material.dart';
import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:gliding_aid/ui/viewmodels/settings_view_model.dart';
import 'package:gliding_aid/ui/views/Pages/home_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

class GlidingAid extends StatelessWidget {
  const GlidingAid({super.key, required this.arguments});

  final List<String> arguments;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MapViewModel>(
          create: (context) => MapViewModel(filesToParse: arguments),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(arguments: arguments),
        )
      ],
      child: MaterialApp(
        title: 'GlidingAid',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('fr')],
        home: MyHomePage(title: 'GlidingAid'),
      ),
    );
  }
}
