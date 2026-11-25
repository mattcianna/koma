import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:mangadex_api_client/src/interceptors/koma_user_agent_interceptor.dart';

/// A chapter entry discovered from an official publisher RSS/Atom feed.
class OfficialFeedChapter extends Equatable {
  /// Creates an [OfficialFeedChapter].
  const new({
    required this.chapterNumber,
    required this.id,
    required this.externalUrl,
    this.publishedAt,
  });

  /// Normalized chapter number string (e.g. `'448'`, `'72'`, `'12.5'`).
  final String chapterNumber;

  /// Deterministic identifier (`<= 36` chars) suitable for Firestore storage.
  final String id;

  /// Direct official publisher episode URL.
  final String externalUrl;

  /// Publication timestamp parsed from the feed item, if available.
  final DateTime? publishedAt;

  @override
  List<Object?> get props => [chapterNumber, id, externalUrl, publishedAt];
}

/// Discovers and parses official publisher RSS/Atom chapter feeds linked from
/// MangaDex `attributes.links['raw']` (such as Kodansha Magazine Pocket and
/// Shogakukan Sunday Webry GigaViewer feeds).
class OfficialReleaseFeedService {
  /// Creates an [OfficialReleaseFeedService].
  ///
  /// If [dio] is omitted, configures a standalone [Dio] client with short
  /// timeouts and the Koma `User-Agent`.
  new({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
              sendTimeout: const Duration(seconds: 6),
              headers: const <String, dynamic>{
                'User-Agent': KomaUserAgentInterceptor.komaUserAgent,
              },
            ),
          );

  final Dio _dio;

  static final RegExp _linkTagRegex = RegExp(
    r'<link\b[^>]*>',
    caseSensitive: false,
  );
  static final RegExp _attrHrefRegex = RegExp(
    r'''href\s*=\s*(?:"([^"]*)"|'([^']*)')''',
    caseSensitive: false,
  );
  static final RegExp _attrTypeRegex = RegExp(
    r'''type\s*=\s*(?:"([^"]*)"|'([^']*)')''',
    caseSensitive: false,
  );

  static final RegExp _bracketKeywordChapterRegex = RegExp(
    r'【[^】]*?(?:満足度|第|GAME|CHAPTER|CH\.?|EPISODE|EP\.?|#|話|章|回)[^】]*?0*(\d+(?:\.\d+)?)[^】]*】',
    caseSensitive: false,
  );
  static final RegExp _pureBracketNumberRegex = RegExp(
    r'【\s*#?0*(\d+(?:\.\d+)?)\s*】',
  );
  static final RegExp _keywordChapterRegex = RegExp(
    r'(?:(?:GAME|CHAPTER|CH\.?|EPISODE|EP\.?|#)\s*0*(\d+(?:\.\d+)?)|第\s*0*(\d+(?:\.\d+)?)(?:話|章|回))(?![A-Za-z0-9.\s]*(?:巻|部|弾|万|億|円|%|vol))(?=$|[^A-Za-z0-9.])',
    caseSensitive: false,
  );

  static final RegExp _itemBlockRegex = RegExp(
    r'<item\b[^>]*>([\s\S]*?)</item>',
    caseSensitive: false,
  );
  static final RegExp _entryBlockRegex = RegExp(
    r'<entry\b[^>]*>([\s\S]*?)</entry>',
    caseSensitive: false,
  );

  /// Extracts an alternate RSS or Atom feed URL from HTML `<link>` tags,
  /// preferring `application/rss+xml` when both RSS and Atom links exist.
  static String? extractFeedUrlFromHtml(
    String html, {
    required String baseUrl,
  }) {
    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null) return null;

    String? atomFallback;
    for (final match in _linkTagRegex.allMatches(html)) {
      final tag = match.group(0);
      if (tag == null) continue;

      final typeMatch = _attrTypeRegex.firstMatch(tag);
      final type = (typeMatch?.group(1) ?? typeMatch?.group(2) ?? '')
          .trim()
          .toLowerCase();
      if (type != 'application/rss+xml' && type != 'application/atom+xml') {
        continue;
      }

      final hrefMatch = _attrHrefRegex.firstMatch(tag);
      final href = (hrefMatch?.group(1) ?? hrefMatch?.group(2) ?? '').trim();
      if (href.isEmpty) continue;

      final resolved = baseUri.resolve(_unescapeXml(href)).toString();
      if (type == 'application/rss+xml') {
        return resolved;
      }
      atomFallback ??= resolved;
    }
    return atomFallback;
  }

  /// Extracts a normalized chapter number from an episode title string,
  /// returning `null` for non-chapter announcements or volume promos.
  static String? extractChapterNumberFromTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    for (final regex in [
      _bracketKeywordChapterRegex,
      _pureBracketNumberRegex,
      _keywordChapterRegex,
    ]) {
      final match = regex.firstMatch(trimmed);
      final rawNumber =
          match?.group(1) ??
          (match != null && match.groupCount >= 2 ? match.group(2) : null);
      if (rawNumber != null && rawNumber.isNotEmpty) {
        return _normalizeNumber(rawNumber);
      }
    }
    return null;
  }

  /// Parses an RSS 2.0 or Atom XML document into deduplicated
  /// [OfficialFeedChapter] items.
  static List<OfficialFeedChapter> parseFeedXml(String xmlContent) {
    if (xmlContent.trim().isEmpty) return const [];

    final chapters = <OfficialFeedChapter>[];
    final seenNumbers = <String>{};

    for (final match in _itemBlockRegex.allMatches(xmlContent)) {
      final block = match.group(1) ?? '';
      final parsed = _parseRssItem(block);
      if (parsed != null && seenNumbers.add(parsed.chapterNumber)) {
        chapters.add(parsed);
      }
    }

    if (chapters.isEmpty) {
      for (final match in _entryBlockRegex.allMatches(xmlContent)) {
        final block = match.group(1) ?? '';
        final parsed = _parseAtomEntry(block);
        if (parsed != null && seenNumbers.add(parsed.chapterNumber)) {
          chapters.add(parsed);
        }
      }
    }

    return List<OfficialFeedChapter>.unmodifiable(chapters);
  }

  /// Fetches chapters from an official publisher `links['raw']` web page by
  /// discovering its RSS/Atom `<link>` and parsing the feed XML.
  ///
  /// Returns an empty list on invalid URLs or network errors so callers
  /// safely fall back to MangaDex data.
  Future<List<OfficialFeedChapter>> fetchChaptersFromRawUrl(
    String? rawUrl,
  ) async {
    if (rawUrl == null || !rawUrl.startsWith('https://')) {
      return const [];
    }

    try {
      final htmlResponse = await _dio.get<String>(
        rawUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final html = htmlResponse.data;
      if (html == null || html.isEmpty) return const [];

      final feedUrl = extractFeedUrlFromHtml(html, baseUrl: rawUrl);
      if (feedUrl == null || !feedUrl.startsWith('https://')) {
        return const [];
      }

      final xmlResponse = await _dio.get<String>(
        feedUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final xml = xmlResponse.data;
      if (xml == null || xml.isEmpty) return const [];

      return parseFeedXml(xml);
    } on Object catch (_) {
      return const [];
    }
  }

  static OfficialFeedChapter? _parseRssItem(String block) {
    final title = _extractTagText(block, 'title');
    if (title == null) return null;

    final chapterNumber = extractChapterNumberFromTitle(title);
    if (chapterNumber == null) return null;

    final link = _extractTagText(block, 'link') ?? '';
    final guid = _extractTagText(block, 'guid');
    final pubDateRaw = _extractTagText(block, 'pubDate');
    final id = _buildExternalId(
      rawIdentifier: guid ?? link,
      fallbackSeed: chapterNumber,
    );

    return OfficialFeedChapter(
      chapterNumber: chapterNumber,
      id: id,
      externalUrl: link,
      publishedAt: _parseDate(pubDateRaw),
    );
  }

  static OfficialFeedChapter? _parseAtomEntry(String block) {
    final title = _extractTagText(block, 'title');
    if (title == null) return null;

    final chapterNumber = extractChapterNumberFromTitle(title);
    if (chapterNumber == null) return null;

    final link = _extractAtomAlternateLink(block) ?? '';
    final rawId = _extractTagText(block, 'id');
    final updatedRaw =
        _extractTagText(block, 'updated') ??
        _extractTagText(block, 'published');
    final id = _buildExternalId(
      rawIdentifier: rawId ?? link,
      fallbackSeed: chapterNumber,
    );

    return OfficialFeedChapter(
      chapterNumber: chapterNumber,
      id: id,
      externalUrl: link,
      publishedAt: _parseDate(updatedRaw),
    );
  }

  static String? _extractTagText(String block, String tagName) {
    final regex = RegExp(
      '<$tagName\\b[^>]*>([\\s\\S]*?)</$tagName>',
      caseSensitive: false,
    );
    final match = regex.firstMatch(block);
    final raw = match?.group(1);
    if (raw == null) return null;

    var cleaned = raw.trim();
    if (cleaned.startsWith('<![CDATA[') && cleaned.endsWith(']]>')) {
      cleaned = cleaned.substring(9, cleaned.length - 3).trim();
    }
    cleaned = _unescapeXml(cleaned).trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static String? _extractAtomAlternateLink(String block) {
    for (final match in _linkTagRegex.allMatches(block)) {
      final tag = match.group(0);
      if (tag == null) continue;
      final lowerTag = tag.toLowerCase();
      if (lowerTag.contains('rel="enclosure"') ||
          lowerTag.contains("rel='enclosure'")) {
        continue;
      }
      final hrefMatch = _attrHrefRegex.firstMatch(tag);
      final href = (hrefMatch?.group(1) ?? hrefMatch?.group(2) ?? '').trim();
      if (href.isNotEmpty) {
        return _unescapeXml(href);
      }
    }
    return null;
  }

  static String _buildExternalId({
    required String rawIdentifier,
    required String fallbackSeed,
  }) {
    final segments = rawIdentifier
        .trim()
        .split(RegExp('[/:?#]+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final candidate = segments.isNotEmpty ? segments.last : fallbackSeed;
    final sanitized = candidate.replaceAll(RegExp('[^A-Za-z0-9._-]'), '');
    final token = sanitized.isEmpty ? fallbackSeed : sanitized;
    final prefixed = 'ext:$token';
    return prefixed.length <= 36 ? prefixed : prefixed.substring(0, 36);
  }

  static String _normalizeNumber(String raw) {
    final dotIndex = raw.indexOf('.');
    if (dotIndex < 0) {
      final parsed = int.tryParse(raw);
      return parsed?.toString() ?? raw;
    }
    final intPart = raw.substring(0, dotIndex);
    final fracPart = raw.substring(dotIndex + 1);
    final normalizedInt = (int.tryParse(intPart) ?? intPart).toString();
    return '$normalizedInt.$fracPart';
  }

  static String _unescapeXml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso.toUtc();

    // Parse RFC 2822 timestamps such as "Wed, 11 Nov 2026 00:00:00 +0900".
    final rfcMatch = RegExp(
      r'^(?:[A-Za-z]{3},\s*)?(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s*([+-]\d{4}|GMT|UTC)?$',
    ).firstMatch(trimmed);
    if (rfcMatch == null) return null;

    const months = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };

    final month = months[rfcMatch.group(2)!.toLowerCase()];
    if (month == null) return null;

    final day = int.parse(rfcMatch.group(1)!);
    final year = int.parse(rfcMatch.group(3)!);
    final hour = int.parse(rfcMatch.group(4)!);
    final minute = int.parse(rfcMatch.group(5)!);
    final second = int.parse(rfcMatch.group(6)!);
    final tz = rfcMatch.group(7);

    var offsetMinutes = 0;
    if (tz != null && tz != 'GMT' && tz != 'UTC' && tz.length == 5) {
      final sign = tz.startsWith('-') ? -1 : 1;
      final tzHours = int.tryParse(tz.substring(1, 3)) ?? 0;
      final tzMins = int.tryParse(tz.substring(3, 5)) ?? 0;
      offsetMinutes = sign * (tzHours * 60 + tzMins);
    }

    final utc = DateTime.utc(year, month, day, hour, minute, second);
    return utc.subtract(Duration(minutes: offsetMinutes));
  }
}
