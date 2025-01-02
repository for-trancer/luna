import 'package:json_annotation/json_annotation.dart';

part 'data_model.g.dart';

@JsonSerializable()
class DataModel {
  @JsonKey(name: 'entity')
  String? entity;
  @JsonKey(name: 'score')
  double? score;
  @JsonKey(name: 'index')
  int? index;
  @JsonKey(name: 'word')
  String? word;
  @JsonKey(name: 'start')
  int? start;
  @JsonKey(name: 'end')
  int? end;

  DataModel({
    this.entity,
    this.score,
    this.index,
    this.word,
    this.start,
    this.end,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return _$DataModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$DataModelToJson(this);
}
