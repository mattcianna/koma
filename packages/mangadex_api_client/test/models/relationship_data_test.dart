import 'package:mangadex_api_client/mangadex_api_client.dart';
import 'package:test/test.dart';

void main() {
  group('RelationshipData', () {
    test('deserializes unexpanded relationship without attributes safely', () {
      final json = <String, dynamic>{'id': 'rel-artist-001', 'type': 'artist'};

      final rel = RelationshipData.fromJson(json);

      expect(rel.id, equals('rel-artist-001'));
      expect(rel.type, equals('artist'));
      expect(rel.attributes, isNull);
      expect(rel.related, isNull);
    });

    test('deserializes expanded relationship with attributes', () {
      final json = <String, dynamic>{
        'id': 'rel-cover-001',
        'type': 'cover_art',
        'attributes': {'fileName': 'cover.jpg', 'volume': '1'},
      };

      final rel = RelationshipData.fromJson(json);

      expect(rel.id, equals('rel-cover-001'));
      expect(rel.type, equals('cover_art'));
      expect(rel.attributes?['fileName'], equals('cover.jpg'));
    });

    test('supports manga sub-relationship classification', () {
      final json = <String, dynamic>{
        'id': 'rel-manga-002',
        'type': 'manga',
        'related': 'spin_off',
      };

      final rel = RelationshipData.fromJson(json);
      expect(rel.type, equals('manga'));
      expect(rel.related, equals('spin_off'));
    });

    test('serializes to JSON symmetrically and supports Equatable', () {
      final name = 'Oda'.trim();
      final rel1 = RelationshipData(
        id: 'id-1',
        type: 'author',
        attributes: {'name': name},
      );
      final rel2 = RelationshipData(
        id: 'id-1',
        type: 'author',
        attributes: {'name': name},
      );

      expect(rel1, equals(rel2));
      expect(rel1.toJson()['type'], equals('author'));
      expect(rel1.props, isNotEmpty);
    });
  });
}
