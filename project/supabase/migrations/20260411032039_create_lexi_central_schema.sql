/*
  # Lexi Central — Core Schema

  ## Overview
  Creates the foundational database schema for Lexi Central, a video-first personal
  media vault with notes, sync, and MEGA.nz bridge support.

  ## New Tables

  ### `media_entries`
  Stores metadata for each media item (video or image). Actual files are stored locally
  on device. MEGA.nz links are stored here as the `source_link` field.

  Columns:
  - `id` (uuid, PK) — Unique entry ID
  - `user_id` (uuid, FK → auth.users) — Owner of the entry
  - `title` (text) — Display title
  - `type` (text) — "video" | "image"
  - `notes` (text) — Markdown notes attached to this entry
  - `source_link` (text) — MEGA.nz or other external media URL
  - `thumbnail_url` (text) — Remote thumbnail URL (optional)
  - `local_path` (text) — Device-local file path (not synced, device-specific)
  - `is_vaulted` (boolean) — Whether entry is hidden in vault
  - `tags` (text[]) — Optional tags array
  - `media_date` (date) — The date this memory is associated with
  - `duration_seconds` (integer) — Video duration in seconds
  - `file_size_bytes` (bigint) — File size in bytes
  - `created_at` (timestamptz) — Creation timestamp
  - `updated_at` (timestamptz) — Last update timestamp

  ## Security
  - RLS enabled — users can only access their own entries
  - Four separate policies for SELECT, INSERT, UPDATE, DELETE

  ## Indexes
  - Index on user_id for fast user-based queries
  - Index on media_date for calendar view performance
  - Index on is_vaulted for vault filtering
*/

CREATE TABLE IF NOT EXISTS media_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL DEFAULT '',
  type text NOT NULL DEFAULT 'video' CHECK (type IN ('video', 'image')),
  notes text NOT NULL DEFAULT '',
  source_link text NOT NULL DEFAULT '',
  thumbnail_url text NOT NULL DEFAULT '',
  local_path text NOT NULL DEFAULT '',
  is_vaulted boolean NOT NULL DEFAULT false,
  tags text[] NOT NULL DEFAULT '{}',
  media_date date NOT NULL DEFAULT CURRENT_DATE,
  duration_seconds integer NOT NULL DEFAULT 0,
  file_size_bytes bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE media_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own media entries"
  ON media_entries FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own media entries"
  ON media_entries FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own media entries"
  ON media_entries FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own media entries"
  ON media_entries FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS media_entries_user_id_idx ON media_entries(user_id);
CREATE INDEX IF NOT EXISTS media_entries_media_date_idx ON media_entries(media_date);
CREATE INDEX IF NOT EXISTS media_entries_is_vaulted_idx ON media_entries(is_vaulted);

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER media_entries_updated_at
  BEFORE UPDATE ON media_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
