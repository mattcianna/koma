// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChapterAttributes _$ChapterAttributesFromJson(Map<String, dynamic> json) =>
    ChapterAttributes(
      volume: _emptyStringToNull(json['volume']),
      chapter: _emptyStringToNull(json['chapter']),
      title: json['title'] as String?,
      translatedLanguage: json['translatedLanguage'] as String?,
      externalUrl: json['externalUrl'] as String?,
      publishAt: json['publishAt'] == null
          ? null
          : DateTime.parse(json['publishAt'] as String),
      readableAt: json['readableAt'] == null
          ? null
          : DateTime.parse(json['readableAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      pages: (json['pages'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChapterAttributesToJson(ChapterAttributes instance) =>
    <String, dynamic>{
      'volume': instance.volume,
      'chapter': instance.chapter,
      'title': instance.title,
      'translatedLanguage': instance.translatedLanguage,
      'externalUrl': instance.externalUrl,
      'publishAt': instance.publishAt?.toIso8601String(),
      'readableAt': instance.readableAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'pages': instance.pages,
      'version': instance.version,
    };

ChapterData _$ChapterDataFromJson(Map<String, dynamic> json) => ChapterData(
  id: json['id'] as String,
  attributes: ChapterAttributes.fromJson(
    json['attributes'] as Map<String, dynamic>,
  ),
  type: json['type'] as String? ?? 'chapter',
  relationships:
      (json['relationships'] as List<dynamic>?)
          ?.map((e) => RelationshipData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ChapterDataToJson(ChapterData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'attributes': instance.attributes,
      'relationships': instance.relationships,
    };

ChapterFeedResponse _$ChapterFeedResponseFromJson(Map<String, dynamic> json) =>
    ChapterFeedResponse(
      result: json['result'] as String? ?? 'ok',
      response: json['response'] as String? ?? 'collection',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => ChapterData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ChapterFeedResponseToJson(
  ChapterFeedResponse instance,
) => <String, dynamic>{
  'result': instance.result,
  'response': instance.response,
  'data': instance.data,
  'limit': instance.limit,
  'offset': instance.offset,
  'total': instance.total,
};
