import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'relationship_data.g.dart';

/// Single relationship entry in MangaDex resource payloads.
@JsonSerializable()
class RelationshipData extends Equatable {
  /// Creates a [RelationshipData].
  const new({
    required this.id,
    required this.type,
    this.related,
    this.attributes,
  });

  /// Factory constructor for deserializing from JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$RelationshipDataFromJson(json);

  /// Resource identifier of the related entity.
  final String id;

  /// Relationship type (e.g. `'author'`, `'artist'`, `'cover_art'`, `'manga'`).
  final String type;

  /// Sub-relationship classification when [type] is `'manga'`
  /// (e.g. `'doujinshi'`, `'spin_off'`, `'colored'`).
  final String? related;

  /// Expanded relationship attributes if requested via `includes[]`.
  ///
  /// Null for unexpanded relationships.
  final Map<String, dynamic>? attributes;

  /// Converts this [RelationshipData] into a JSON map.
  Map<String, dynamic> toJson() => _$RelationshipDataToJson(this);

  @override
  List<Object?> get props => [id, type, related, attributes];
}
