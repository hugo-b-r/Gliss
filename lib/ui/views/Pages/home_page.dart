import 'package:flutter/material.dart';
import 'package:gliding_aid/ui/views/Pages/db_provider_widget.dart';
import 'package:gliding_aid/ui/views/Pages/home_page_common.dart';
import 'package:gliding_aid/ui/views/widgets/menu_toolbar.dart';


class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    // we need a layoutbuilder widget https://clouddevs.com/flutter/responsive-design/#:~:text=The%20LayoutBuilder%20widget%20gives%20you,adapt%20to%20different%20screen%20sizes.
    return DbProviderWidget(
      child: Scaffold(
        body: Stack(
          // alignment: Alignment.center, // <---------
          children: [
            LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth > 900) {
                return const HorizontalHomePage();
              } else {
                return const VerticalHomePage();
              }
            }),
            Positioned(
                top: 10,
                right: 10,
                child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(60)),
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: const Offset(
                              5.0,
                              5.0,
                            ),
                            blurRadius: 10.0,
                            spreadRadius: 2.0,
                          ), //BoxShadow
                        ]),
                    child: const TopToolbar())),
          ],
        ),
      ),
    );
  }
}
