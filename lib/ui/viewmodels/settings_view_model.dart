import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsViewModel extends ChangeNotifier {
  List<String> arguments = [];
  String appName = "";
  String packageName = "";
  String appVersion = "";
  String appBuildNumber = "";

  SettingsViewModel({required this.arguments}) {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      appVersion = packageInfo.version;
      appBuildNumber = packageInfo.buildNumber;
    });{

    }
  }
}