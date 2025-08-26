import 'package:gliding_aid/utils/turnpoint.dart';
import 'package:xml/xml.dart';

class Task {
  List<Turnpoint> turnpoints = [];

  /// Raw time (seconds past midnight). The time after which pilots can start.
  int startTime = 0;

  /// Raw time (seconds past midnight). The time after which the race must have been finished.
  int endTime = 0;

  Task(this.turnpoints, this.startTime, this.endTime);

  /// Creates a task from a LK8000 task. Format seems to also be used by XCSoar.
  Task.createFromLktFile(String filecontent) {
    XmlDocument domTree = XmlDocument.parse(filecontent);

    // hwat if these tags are missing ?
    var taskpoints = domTree.findElements("taskpoints").first;
    var waypoints = domTree.findElements("waypoints").first;
    var gate = domTree.findElements("time-gate").first;
    List<XmlElement> tpoints = List.from(taskpoints.findElements("point"));
    List<XmlElement> wpoints = List.from(waypoints.findElements("point"));
    String startTimeHm = gate.getAttribute("open-time") ?? "00:00";

    List<String> stSp = startTimeHm.split(":");
    // concert start time from HH:MM to seconds
    var startTime = int.parse(stSp[0]) * 3600 + int.parse(stSp[0]) * 60;
    int endTime =
        24 * 3600 + 59 * 60 + 59; // default value for end time 23:59:59

    // Creates a dictionnary of names and a list of longitudes and latitudes
    Map<String, List<double>> coordinates = {};
    for (final point in wpoints) {
      String name = point.getAttribute("name") ?? "p";
      double longitude = double.parse(point.getAttribute("longitude") ?? "0");
      double latitude = double.parse(point.getAttribute("latitude") ?? "0");
      if (coordinates.containsKey(name)) {
        coordinates[name]?.add(longitude);
        coordinates[name]?.add(latitude);
      } else {
        coordinates[name] = [longitude, latitude];
      }
    }
    var kind = "";
    // Create a list of turnpoints
    for (final point in tpoints) {
      // get coordinates from wpoints
      var lat = (coordinates[point.getAttribute("name") ?? "p"] ?? [0, 0])[1];
      var lon = (coordinates[point.getAttribute("name") ?? "p"] ?? [0, 0])[0];
      double radius = double.parse(point.getAttribute("radius") ?? "0") / 1000;

      if (point == tpoints[0]) {
        // It is the start, the first turnpoint
        kind = ((point.getAttribute("Exit") ?? "false") == "true")
            ? "start_exit"
            : "start_enter";
      } else {
        if (point == tpoints[-1]) {
          // It is the last turnpoint
          kind = ((point.getAttribute("type") ?? "line") == "line")
              ? "goal_cylinder"
              : "goal_cylinder";
        } else {
          // All other turnpoints are cylinders
          kind = "cylinder";
        }
      }
      var turnpoint = Turnpoint(lat, lon, radius, kind);
      turnpoints.add(turnpoint);
    }
    turnpoints = turnpoints;
    startTime = startTime;
    endTime = endTime;
  }
}