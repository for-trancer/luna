// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DataModel _$DataModelFromJson(Map<String, dynamic> json) => DataModel(
      entity: json['entity'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      index: (json['index'] as num?)?.toInt(),
      word: json['word'] as String?,
      start: (json['start'] as num?)?.toInt(),
      end: (json['end'] as num?)?.toInt(),
    );

Map<String, dynamic> _$DataModelToJson(DataModel instance) => <String, dynamic>{
      'entity': instance.entity,
      'score': instance.score,
      'index': instance.index,
      'word': instance.word,
      'start': instance.start,
      'end': instance.end,
    };
