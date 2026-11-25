import Bottleneck from 'bottleneck';
import { request } from 'undici';
import { CONFIG } from '../config';
import {
  MangaDexChapterData,
  MangaDexEntityResponse,
  MangaDexFeedResponse,
  OfficialFeedChapter,
} from '../types/mangadex';
import * as logger from 'firebase-functions/logger';

export class MangaDexClient {
  private limiter: Bottleneck;

  constructor() {
    this.limiter = new Bottleneck({
      maxConcurrent: 1,
      minTime: CONFIG.mangadex.minTimeBetweenRequestsMs,
      reservoir: 4,
      reservoirRefreshInterval: 1000,
      reservoirRefreshAmount: 4,
    });

    this.limiter.on('failed', async (error, jobInfo) => {
      logger.warn(`MangaDex request failed (attempt ${jobInfo.retryCount + 1}):`, error);
      if (jobInfo.retryCount < 3) {
        return 1000 * Math.pow(2, jobInfo.retryCount);
      }
      return undefined;
    });
  }

  /**
   * Formats a Date object to MangaDex UTC publishAtSince format: YYYY-MM-DDTHH:mm:ss
   * Omits milliseconds and 'Z' suffix to comply with MangaDex validation regex.
   */
  public static formatPublishAtSince(date: Date): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    const yyyy = date.getUTCFullYear();
    const mm = pad(date.getUTCMonth() + 1);
    const dd = pad(date.getUTCDate());
    const hh = pad(date.getUTCHours());
    const min = pad(date.getUTCMinutes());
    const ss = pad(date.getUTCSeconds());
    return `${yyyy}-${mm}-${dd}T${hh}:${min}:${ss}`;
  }

  /**
   * Fetches chapters published since `publishAtSince` for a specific manga and languages.
   * NOTE: includeEmptyPages is intentionally omitted so official simulpubs (pages: 0, externalUrl != null)
   * are included in the results.
   */
  public async getMangaFeed(
    mangaId: string,
    languages: string[],
    since: Date,
  ): Promise<MangaDexChapterData[]> {
    const formattedSince = MangaDexClient.formatPublishAtSince(since);
    const url = new URL(`${CONFIG.mangadex.baseUrl}/manga/${mangaId}/feed`);

    url.searchParams.set('limit', CONFIG.mangadex.feedPageLimit.toString());
    url.searchParams.set('order[publishAt]', 'desc');
    url.searchParams.set('publishAtSince', formattedSince);

    for (const lang of languages) {
      url.searchParams.append('translatedLanguage[]', lang);
    }

    return this.limiter.schedule(async () => {
      logger.info(
        `Fetching MangaDex feed for manga ${mangaId} (languages: ${languages.length > 0 ? languages.join(',') : 'all'})`,
      );
      const response = await request(url.toString(), {
        method: 'GET',
        headers: {
          'User-Agent': CONFIG.mangadex.userAgent,
          'Accept': 'application/json',
        },
      });

      if (response.statusCode === 429) {
        const retryAfter = response.headers['x-ratelimit-retry-after'];
        logger.error(`MangaDex rate limit hit for ${mangaId}. Retry-After: ${retryAfter}`);
        throw new Error(`MangaDex rate limit (429) encountered. Retry-After: ${retryAfter}`);
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        const bodyText = await response.body.text();
        throw new Error(
          `MangaDex API error [${response.statusCode}] on ${url.toString()}: ${bodyText}`,
        );
      }

      const body = (await response.body.json()) as MangaDexFeedResponse;
      if (body.result !== 'ok' || !Array.isArray(body.data)) {
        logger.warn(`Unexpected MangaDex feed payload for manga ${mangaId}:`, body);
        return [];
      }

      return body.data;
    });
  }

  /**
   * Fetches `attributes.links.raw` for a manga on MangaDex, if configured.
   */
  public async getMangaRawUrl(mangaId: string): Promise<string | null> {
    const url = `${CONFIG.mangadex.baseUrl}/manga/${mangaId}`;
    return this.limiter.schedule(async () => {
      try {
        const response = await request(url, {
          method: 'GET',
          headers: {
            'User-Agent': CONFIG.mangadex.userAgent,
            'Accept': 'application/json',
          },
        });
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }
        const body = (await response.body.json()) as MangaDexEntityResponse;
        const rawLinks = body.data?.attributes?.links;
        if (!rawLinks || Array.isArray(rawLinks)) return null;
        const rawUrl = rawLinks.raw;
        return typeof rawUrl === 'string' && rawUrl.startsWith('https://')
          ? rawUrl
          : null;
      } catch (err) {
        logger.warn(`Failed reading links.raw for ${mangaId}:`, err);
        return null;
      }
    });
  }

  /**
   * Discovers official RSS/Atom release feeds linked from `links.raw`
   * (such as Kodansha Magazine Pocket and Shogakukan Sunday Webry) and parses
   * published episodes.
   */
  public async getOfficialFeedChapters(
    rawUrl: string,
  ): Promise<OfficialFeedChapter[]> {
    if (!rawUrl || !rawUrl.startsWith('https://')) {
      return [];
    }

    try {
      const htmlRes = await request(rawUrl, {
        method: 'GET',
        headers: { 'User-Agent': CONFIG.mangadex.userAgent },
      });
      if (htmlRes.statusCode < 200 || htmlRes.statusCode >= 300) {
        return [];
      }
      const html = await htmlRes.body.text();
      const feedUrl = MangaDexClient.extractFeedUrlFromHtml(html, rawUrl);
      if (!feedUrl || !feedUrl.startsWith('https://')) {
        return [];
      }

      const xmlRes = await request(feedUrl, {
        method: 'GET',
        headers: { 'User-Agent': CONFIG.mangadex.userAgent },
      });
      if (xmlRes.statusCode < 200 || xmlRes.statusCode >= 300) {
        return [];
      }
      const xml = await xmlRes.body.text();
      return MangaDexClient.parseOfficialFeedXml(xml);
    } catch (err) {
      logger.warn(`Official feed fetch failed for ${rawUrl}:`, err);
      return [];
    }
  }

  public static extractFeedUrlFromHtml(
    html: string,
    baseUrl: string,
  ): string | null {
    const linkTagRegex = /<link\b[^>]*>/gi;
    const typeRegex = /type\s*=\s*(?:"([^"]*)"|'([^']*)')/i;
    const hrefRegex = /href\s*=\s*(?:"([^"]*)"|'([^']*)')/i;

    let atomFallback: string | null = null;
    for (const match of html.matchAll(linkTagRegex)) {
      const tag = match[0];
      const typeMatch = tag.match(typeRegex);
      const type = (typeMatch?.[1] ?? typeMatch?.[2] ?? '').trim().toLowerCase();
      if (type !== 'application/rss+xml' && type !== 'application/atom+xml') {
        continue;
      }
      const hrefMatch = tag.match(hrefRegex);
      const href = (hrefMatch?.[1] ?? hrefMatch?.[2] ?? '').trim();
      if (!href) continue;

      try {
        const resolved = new URL(MangaDexClient.unescapeXml(href), baseUrl).toString();
        if (type === 'application/rss+xml') return resolved;
        atomFallback ??= resolved;
      } catch {
        continue;
      }
    }
    return atomFallback;
  }

  public static extractChapterNumberFromTitle(title: string): string | null {
    const trimmed = title.trim();
    if (!trimmed) return null;

    const regexes = [
      /【[^】]*?(?:満足度|第|GAME|CHAPTER|CH\.?|EPISODE|EP\.?|#|話|章|回)[^】]*?0*(\d+(?:\.\d+)?)[^】]*】/i,
      /【\s*#?0*(\d+(?:\.\d+)?)\s*】/,
      /(?:(?:GAME|CHAPTER|CH\.?|EPISODE|EP\.?|#)\s*0*(\d+(?:\.\d+)?)|第\s*0*(\d+(?:\.\d+)?)(?:話|章|回))(?![A-Za-z0-9.\s]*(?:巻|部|弾|万|億|円|%|vol))(?=$|[^A-Za-z0-9.])/i,
    ];

    for (const regex of regexes) {
      const m = trimmed.match(regex);
      const raw = m?.[1] ?? m?.[2];
      if (raw) {
        return MangaDexClient.normalizeChapterNumber(raw);
      }
    }
    return null;
  }

  public static parseOfficialFeedXml(xml: string): OfficialFeedChapter[] {
    if (!xml.trim()) return [];
    const results: OfficialFeedChapter[] = [];
    const seen = new Set<string>();

    const extractTag = (block: string, tag: string): string | null => {
      const m = block.match(new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)</${tag}>`, 'i'));
      if (!m?.[1]) return null;
      let val = m[1].trim();
      if (val.startsWith('<![CDATA[') && val.endsWith(']]>')) {
        val = val.slice(9, -3).trim();
      }
      val = MangaDexClient.unescapeXml(val).trim();
      return val || null;
    };

    const buildId = (rawId: string, fallback: string): string => {
      const segs = rawId.trim().split(/[/:?#]+/).filter(Boolean);
      const last = segs.length > 0 ? segs[segs.length - 1] : fallback;
      const clean = last.replace(/[^A-Za-z0-9._-]/g, '') || fallback;
      return `ext:${clean}`.slice(0, 36);
    };

    const parseDate = (raw: string | null): Date | null => {
      if (!raw) return null;
      const ms = Date.parse(raw.trim());
      return Number.isNaN(ms) ? null : new Date(ms);
    };

    for (const match of xml.matchAll(/<item\b[^>]*>([\s\S]*?)<\/item>/gi)) {
      const block = match[1];
      const title = extractTag(block, 'title');
      if (!title) continue;
      const chapterNumber = MangaDexClient.extractChapterNumberFromTitle(title);
      if (!chapterNumber || seen.has(chapterNumber)) continue;

      const link = extractTag(block, 'link') ?? '';
      const guid = extractTag(block, 'guid');
      const pubDate = extractTag(block, 'pubDate');
      seen.add(chapterNumber);
      results.push({
        chapterNumber,
        id: buildId(guid ?? link, chapterNumber),
        externalUrl: link,
        publishedAt: parseDate(pubDate),
      });
    }

    if (results.length === 0) {
      for (const match of xml.matchAll(/<entry\b[^>]*>([\s\S]*?)<\/entry>/gi)) {
        const block = match[1];
        const title = extractTag(block, 'title');
        if (!title) continue;
        const chapterNumber = MangaDexClient.extractChapterNumberFromTitle(title);
        if (!chapterNumber || seen.has(chapterNumber)) continue;

        let link = '';
        for (const lm of block.matchAll(/<link\b[^>]*>/gi)) {
          const tag = lm[0];
          if (/rel\s*=\s*["']enclosure["']/i.test(tag)) continue;
          const hm = tag.match(/href\s*=\s*(?:"([^"]*)"|'([^']*)')/i);
          const href = (hm?.[1] ?? hm?.[2] ?? '').trim();
          if (href) {
            link = MangaDexClient.unescapeXml(href);
            break;
          }
        }
        const rawId = extractTag(block, 'id');
        const updated = extractTag(block, 'updated') ?? extractTag(block, 'published');
        seen.add(chapterNumber);
        results.push({
          chapterNumber,
          id: buildId(rawId ?? link, chapterNumber),
          externalUrl: link,
          publishedAt: parseDate(updated),
        });
      }
    }

    return results;
  }

  private static normalizeChapterNumber(raw: string): string {
    const dot = raw.indexOf('.');
    if (dot < 0) {
      const n = Number.parseInt(raw, 10);
      return Number.isNaN(n) ? raw : n.toString();
    }
    const intPart = raw.slice(0, dot);
    const frac = raw.slice(dot + 1);
    const n = Number.parseInt(intPart, 10);
    return `${Number.isNaN(n) ? intPart : n}.${frac}`;
  }

  private static unescapeXml(input: string): string {
    return input
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .replace(/&apos;/g, "'");
  }
}
