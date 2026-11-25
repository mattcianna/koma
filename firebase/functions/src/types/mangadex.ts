export interface MangaDexChapterAttributes {
  volume: string | null;
  chapter: string | null;
  title: string | null;
  translatedLanguage: string;
  externalUrl: string | null;
  publishAt: string;
  readableAt: string;
  createdAt: string;
  updatedAt: string;
  pages: number;
  version: number;
}

export interface MangaDexChapterData {
  id: string;
  type: 'chapter';
  attributes: MangaDexChapterAttributes;
}

export interface MangaDexFeedResponse {
  result: 'ok' | 'error';
  response: 'collection';
  data: MangaDexChapterData[];
  limit: number;
  offset: number;
  total: number;
}

export interface MangaDexEntityResponse {
  result: 'ok' | 'error';
  data?: {
    id: string;
    attributes?: {
      links?: Record<string, string> | unknown[];
    };
  };
}

export interface OfficialFeedChapter {
  chapterNumber: string;
  id: string;
  externalUrl: string;
  publishedAt: Date | null;
}
