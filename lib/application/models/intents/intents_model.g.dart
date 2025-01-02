// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intents_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntentsModel _$IntentsModelFromJson(Map<String, dynamic> json) => IntentsModel(
      label: json['label'] as String?,
      score: (json['score'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$IntentsModelToJson(IntentsModel instance) =>
    <String, dynamic>{
      'label': instance.label,
      'score': instance.score,
    };
