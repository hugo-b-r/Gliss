import 'gnss_fix.dart';

class Glide {
  /// Represents a single glide detected in a flight
  ///
  /// Glides are portions of the recorded track between thermals
  ///
  /// Attributes:
  ///   enter_fix : a GNSSFix, entry poit of the glide
  ///   exit_fix : a GNSSFix, exit point of the glide
  ///   track_length : a double : the total length, in kilometers, of the recorded
  ///     track between the entry point and the exit point, note that this is not
  ///     the same as he distance between these points

  GNSSFix enterFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  GNSSFix exitFix = GNSSFix(0, 0, 0, "0", 0, 0, "0");
  double trackLength = 0;

  Glide(GNSSFix enterFix, GNSSFix exitFix, double trackLength) {
    enterFix = enterFix;
    exitFix = exitFix;
    trackLength = trackLength;
  }

  /// Returns the time spent in the glide, seconds.
  double timeChange() {
    return exitFix.timestamp - enterFix.timestamp;
  }

  /// Returns the average speed in the glide, km/h.
  double speed() {
    return trackLength / (timeChange() / 3600);
  }

  /// Return the overall altitude change in the glide, meters.
  double altChange() {
    return exitFix.alt - enterFix.alt;
  }

  /// Returns the L/D of the glide.
  double glideRatio() {
    if (altChange().abs() < 1e-7) {
      return 0;
    }
    return trackLength * 1000 / altChange();
  }
}