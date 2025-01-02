import 'package:json_annotation/json_annotation.dart';
part 'image_model.g.dart';

@JsonSerializable()
class ImageModel {
  @JsonKey(name: 'image')
  String? image;

  ImageModel({this.image});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return _$ImageModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ImageModelToJson(this);
}
