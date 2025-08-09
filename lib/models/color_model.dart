class ColorModel {
  final String? color;
  final String? name;
  ColorModel({required this.color, required this.name});

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(color: json['color'], name: json['name']);
  }
}
