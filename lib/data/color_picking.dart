import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gliding_aid/l10n/app_localizations.dart';
import 'package:gliding_aid/views/view_models/flight_view_model.dart';

Future<Color> pickColor(BuildContext context, FlightViewModel fl) async {
  var picker_color = fl.color;
  await showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.pickYourColor),
            content: SingleChildScrollView(
              child: MaterialPicker(
                pickerColor: picker_color,
                onColorChanged: (color) => {picker_color = color},
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.done),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ));
  return picker_color;
}
