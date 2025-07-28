class GradientColorModel {
  String? name;
  List<String>? colors;
  String? begin;
  String? end;
  String? transform;

  GradientColorModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['colors'] != null) {
      colors = [];
      json['colors'].forEach((v) {
        colors?.add(v);
      });
    }
    begin = json['begin'];
    end = json['end'];
    transform = json['transform'];
  }
}
