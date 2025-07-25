import 'package:flutter/material.dart';
import 'package:gliding_aid/viewModels/map_model.dart';
import 'package:provider/provider.dart';

class ButtonOpenFile extends StatelessWidget {
  const ButtonOpenFile({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await Provider.of<MapModel>(context, listen: false).openIgcFile();
      },
      child: const Text("Ouvrir un fichier IGC"),
    );
  }
}
