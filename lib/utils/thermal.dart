
import 'gnss_fix.dart';

class Thermal {
  /// Represents a single thermal detected in flight.

  /// Attributes:
  ///  enter_fix: a GNSSFix, entry point of the thermal
  GNSSFix enterFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  GNSSFix exitFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");

  ///  exit_fix: a GNSSFix, exit_point of the thermal

  Thermal(GNSSFix enterFix, GNSSFix exitFix) {
    enterFix = enterFix;
    exitFix = exitFix;
  }

  /// Returns the time spent in the thermal in seconds
  double timeChange() {
    return exitFix.rawtime - enterFix.rawtime;
  }

  /// Retturns the altitude ained/lost in the thermal in meters
  double altChange() {
    return exitFix.alt - enterFix.alt;
  }

  /// Returns average velocity in the thermal in m/s
  double verticalVelocity() {
    if (timeChange().abs() < 1e-7) {
      return 0.0;
    }
    return altChange() / timeChange();
  }
}

