export type MediaType = 'video' | 'image' | 'voice' | 'mark' | 'note';

export interface MediaEntry {
  id: string;
  user_id?: string;
  title: string;
  type: MediaType;
  notes: string;
  source_link: string;
  thumbnail_url: string;
  local_path: string;
  is_vaulted: boolean;
  tags: string[];
  media_date: string;
  duration_seconds: number;
  file_size_bytes: number;
  created_at: string;
  updated_at: string;
}

export type ThemeKey = 'kirby' | 'dark' | 'ocean' | 'forest' | 'midnight' | 'sunset' | 'lavender' | 'monochrome';

export interface ThemeColors {
  primary: string;
  secondary: string;
  accent: string;
  background: string;
  surface: string;
  surfaceElevated: string;
  text: string;
  textSecondary: string;
  textMuted: string;
  border: string;
  success: string;
  warning: string;
  error: string;
  vaultBg: string;
  tabBar: string;
  tabBarActive: string;
  tabBarInactive: string;
  cardShadow: string;
  overlay: string;
}

export interface AppSettings {
  theme: ThemeKey;
  gridColumns: 2 | 3;
  roundedCorners: number;
  shadowIntensity: number;
  autoPlay: boolean;
  loopVideos: boolean;
  defaultMute: boolean;
  defaultEditorMode: 'edit' | 'preview';
  notesFontSize: number;
  vaultEnabled: boolean;
  vaultPin: string;
  autoLockMinutes: number;
  mediaPaths: string[];
  noteTabs: string[];
  galleryTabs: string[];
  pinnedCountdownDates: string[];
  bigTimerSeconds: number;
  bigTimerName: string;
}

export interface MegaFileMetadata {
  name: string;
  size: number;
  type: string;
  streamUrl?: string;
}

export interface CalendarDay {
  date: string;
  entries: MediaEntry[];
}
