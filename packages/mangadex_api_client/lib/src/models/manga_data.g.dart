// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MangaAttributes _$MangaAttributesFromJson(Map<String, dynamic> json) =>
    MangaAttributes(
      title: json['title'] as Map<String, dynamic>? ?? const {},
      altTitles:
          (json['altTitles'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      description: json['description'] == null
          ? const {}
          : _parseDescription(json['description']),
      links: json['links'] == null
          ? const {}
          : _parseDescription(json['links']),
      isLocked: json['isLocked'] as bool?,
      originalLanguage: json['originalLanguage'] as String?,
      lastVolume: _emptyStringToNull(json['lastVolume']),
      lastChapter: _emptyStringToNull(json['lastChapter']),
      publicationDemographic: json['publicationDemographic'] as String?,
      status: json['status'] as String?,
      year: (json['year'] as num?)?.toInt(),
      contentRating: json['contentRating'] as String?,
      availableTranslatedLanguages:
          (json['availableTranslatedLanguages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );

Map<String, dynamic> _$MangaAttributesToJson(MangaAttributes instance) =>
    <String, dynamic>{
      'title': instance.title,
      'altTitles': instance.altTitles,
      'description': instance.description,
      'links': instance.links,
      'isLocked': instance.isLocked,
      'originalLanguage': instance.originalLanguage,
      'lastVolume': instance.lastVolume,
      'lastChapter': instance.lastChapter,
      'publicationDemographic': instance.publicationDemographic,
      'status': instance.status,
      'year': instance.year,
      'contentRating': instance.contentRating,
      'availableTranslatedLanguages': instance.availableTranslatedLanguages,
    };

MangaData _$MangaDataFromJson(Map<String, dynamic> json) => MangaData(
  id: json['id'] as String,
  attributes: MangaAttributes.fromJson(
    json['attributes'] as Map<String, dynamic>,
  ),
  type: json['type'] as String? ?? 'manga',
  relationships:
      (json['relationships'] as List<dynamic>?)
          ?.map((e) => RelationshipData.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MangaDataToJson(MangaData instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'attributes': instance.attributes,
  'relationships': instance.relationships,
};

MangaResponse _$MangaResponseFromJson(Map<String, dynamic> json) =>
    MangaResponse(
      data: MangaData.fromJson(json['data'] as Map<String, dynamic>),
      result: json['result'] as String? ?? 'ok',
      response: json['response'] as String? ?? 'entity',
    );

Map<String, dynamic> _$MangaResponseToJson(MangaResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
      'response': instance.response,
      'data': instance.data,
    };

MangaListResponse _$MangaListResponseFromJson(Map<String, dynamic> json) =>
    MangaListResponse(
      result: json['result'] as String? ?? 'ok',
      response: json['response'] as String? ?? 'collection',
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => MangaData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MangaListResponseToJson(MangaListResponse instance) =>
    <String, dynamic>{
      'result': instance.result,
      'response': instance.response,
      'data': instance.data,
      'limit': instance.limit,
      'offset': instance.offset,
      'total': instance.total,
    };
