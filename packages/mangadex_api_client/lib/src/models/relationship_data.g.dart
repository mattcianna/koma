// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelationshipData _$RelationshipDataFromJson(Map<String, dynamic> json) =>
    RelationshipData(
      id: json['id'] as String,
      type: json['type'] as String,
      related: json['related'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RelationshipDataToJson(RelationshipData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'related': instance.related,
      'attributes': instance.attributes,
    };
