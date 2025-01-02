import 'package:json_annotation/json_annotation.dart';

part 'intents_model.g.dart';

@JsonSerializable()
class IntentsModel {
  @JsonKey(name: 'label')
  String? label;
  @JsonKey(name: 'score')
  double? score;

  IntentsModel({this.label, this.score});

  factory IntentsModel.fromJson(Map<String, dynamic> json) {
    return _$IntentsModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$IntentsModelToJson(this);
}
