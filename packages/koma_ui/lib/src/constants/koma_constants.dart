/// Design system and network constants for the Koma UI package.
library;

/// Standard HTTP headers required for all MangaDex network requests.
///
/// MangaDex v5 requires a custom User-Agent in the format:
/// `App-Name/Version (Contact-URL-or-Email)`.
/// Custom `Referer` headers are strictly forbidden by MangaDex.
const kKomaUserAgentHeaders = <String, String>{
  'User-Agent': 'Koma/0.1.0 (https://github.com/mattcianna/koma)',
};

/// The canonical User-Agent header value for Koma.
const kKomaUserAgent = 'Koma/0.1.0 (https://github.com/mattcianna/koma)';

/// Minimum interactive touch target dimension (in dp) per WCAG 2.2 AA.
const double kKomaMinTouchTarget = 48;
