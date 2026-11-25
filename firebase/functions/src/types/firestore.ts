import { Timestamp } from 'firebase-admin/firestore';

export type ReadingStatus = 'Reading' | 'Plan to Read' | 'Completed' | 'On Hold' | 'Dropped';

export interface UserDocument {
  uid: string;
  email: string;
  displayName?: string | null;
  photoUrl?: string | null;
  uiLocale: 'en' | 'it';
  preferredLanguages: string[];
  contentRatings: string[];
  notificationsEnabled: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface DeviceDocument {
  token: string;
  platform: 'android' | 'ios';
  updatedAt: Timestamp;
}

export interface LibraryDocument {
  mangaId: string;
  uid: string;
  title: string;
  coverFileName?: string | null;
  status: ReadingStatus;
  preferredLanguages: string[];
  readChapters: string[];
  readVolumes: string[];
  lastReadChapter?: string | null;
  lastReadChapterId?: string | null;
  latestKnownChapterId?: string | null;
  latestKnownChapterNumber?: string | null;
  addedAt: Timestamp;
  updatedAt: Timestamp;
}
