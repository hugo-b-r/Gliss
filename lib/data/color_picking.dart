import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gliding_aid/l10n/app_localizations.dart';
import 'package:gliding_aid/ui/viewmodels/flight_view_model.dart';

Future<Color> pickColor(BuildContext context, FlightViewModel fl) async {
  var pickerColor = fl.color;
  await showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.pickYourColor),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (color) => {pickerColor = color},
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
  return pickerColor;
}
