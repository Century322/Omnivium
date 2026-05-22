-- Omnivium Supabase Database Schema
-- Execute in Supabase SQL Editor

-- Enable RLS
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;

-- Sessions
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  model TEXT DEFAULT 'gpt-4o',
  is_archived BOOLEAN DEFAULT false,
  is_favorite BOOLEAN DEFAULT false,
  messages JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Notes
CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  content TEXT DEFAULT '',
  type TEXT DEFAULT 'text',
  is_done BOOLEAN DEFAULT false,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Memories
CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  category TEXT DEFAULT 'general',
  importance REAL DEFAULT 0.5,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Quick Commands
CREATE TABLE IF NOT EXISTS quick_commands (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  label TEXT NOT NULL DEFAULT '',
  prompt TEXT NOT NULL DEFAULT '',
  icon TEXT DEFAULT 'zap',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_updated_at ON sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_quick_commands_user_id ON quick_commands(user_id);

-- RLS Policies
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE quick_commands ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own sessions" ON sessions FOR SELECT USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can insert own sessions" ON sessions FOR INSERT WITH CHECK (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can update own sessions" ON sessions FOR UPDATE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can delete own sessions" ON sessions FOR DELETE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);

CREATE POLICY "Users can read own notes" ON notes FOR SELECT USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can insert own notes" ON notes FOR INSERT WITH CHECK (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can update own notes" ON notes FOR UPDATE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can delete own notes" ON notes FOR DELETE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);

CREATE POLICY "Users can read own memories" ON memories FOR SELECT USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can insert own memories" ON memories FOR INSERT WITH CHECK (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can update own memories" ON memories FOR UPDATE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);

CREATE POLICY "Users can read own quick_commands" ON quick_commands FOR SELECT USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can insert own quick_commands" ON quick_commands FOR INSERT WITH CHECK (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can update own quick_commands" ON quick_commands FOR UPDATE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
CREATE POLICY "Users can delete own quick_commands" ON quick_commands FOR DELETE USING (user_id = auth.jwt()->>'matrix_user_id' OR user_id = auth.uid()::text);
