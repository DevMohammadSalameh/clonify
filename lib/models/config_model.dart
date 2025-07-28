import 'color_model.dart';
import 'gradient_color_model.dart';

class CloneConfigModel {
  String? appName;
  String? clientId;
  String? primaryColor;
  String? packageName;
  List<ColorModel>? colors;
  List<GradientColorModel>? gradientsColors;
  String? baseUrl;
  late String version;

  bool get isValid =>
      (appName?.isNotEmpty ?? false) && (packageName?.isNotEmpty ?? false);

  CloneConfigModel.fromJson(dynamic json) {
    clientId = json['clientId'];
    appName = json['appName'];
    primaryColor = json['primaryColor'];
    packageName = json['packageName'];
    baseUrl = json['baseUrl'];
    version = json['version'] ?? '1.0.0+1';
    if (json['colors'] != null) {
      colors = [];
      json['colors'].forEach((v) {
        colors?.add(ColorModel.fromJson(v));
      });
    }
    if (json['linearGradients'] != null) {
      gradientsColors = [];
      json['linearGradients'].forEach((v) {
        gradientsColors?.add(GradientColorModel.fromJson(v));
      });
    }
  }
}
