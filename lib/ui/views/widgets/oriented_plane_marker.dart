import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gliding_aid/ui/viewmodels/map_view_model.dart';
import 'package:gliding_aid/utils/gnss_fix.dart';
import 'package:provider/provider.dart';

class OrientedPlaneMarker extends StatelessWidget {
  const OrientedPlaneMarker({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MapViewModel, Color>(
        selector: (_, mapVModel) => mapVModel
            .getOverviewColor(), // color is less likely to change than position of the icon
        builder: (_, iconColor, __) {
          return Selector<MapViewModel, bool>(
              selector: (_, mapVModel) => mapVModel
                  .overviewVisibilty, // color is less likely to change than position of the icon
              builder: (_, visible, __) {
                if (visible) {
                  return Selector<MapViewModel, GNSSFix>(
                      selector: (_, mapVModel) => mapVModel
                          .getActualOverviewFix(), // color is less likely to change than position of the icon
                      builder: (_, overviewFix, __) {
                        return MarkerLayer(
                          markers: [
                            Marker(
                              point: overviewFix.toLatLng(),
                              width: 80,
                              height: 80,
                              child: Visibility(
                                visible: visible,
                                child: Transform.rotate(
                                    angle: overviewFix.bearing * math.pi / 180,
                                    child: Icon(
                                      Icons.flight,
                                      color: iconColor,
                                      size: 50,
                                      weight: 3,
                                      shadows: List.generate(
                                        10,
                                        (index) => Shadow(
                                          blurRadius: 2,
                                          color: Theme.of(context).canvasColor,
                                        ),
                                      ),
                                    )),
                              ),
                            ),
                          ],
                        );
                      });
                } else {
                  return const SizedBox.shrink();
                }
              });
        });
  }
}
