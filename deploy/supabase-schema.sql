-- Omnivium Supabase Database Schema
-- 幂等脚本：无论数据库是空的还是已有旧表，跑一遍就到位
-- 在 Supabase SQL Editor 中执行

-- ============================================================
-- 1. 创建缺失的表（IF NOT EXISTS 保证安全）
-- ============================================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL DEFAULT '',
  display_name TEXT,
  avatar_url TEXT,
  matrix_user_id TEXT,
  did TEXT,
  trust_level INT DEFAULT 0,
  plan TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS models (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  tier TEXT NOT NULL DEFAULT 'fast',
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

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

CREATE TABLE IF NOT EXISTS memories (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  category TEXT DEFAULT 'general',
  importance REAL DEFAULT 0.5,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

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

-- ============================================================
-- 2. 为已有旧表补缺失的列（DO $$ ... EXCEPTION 保证幂等）
-- ============================================================

DO $$
BEGIN
  -- sessions 表补列
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='sessions' AND column_name='updated_at') THEN
    ALTER TABLE sessions ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='sessions' AND column_name='is_archived') THEN
    ALTER TABLE sessions ADD COLUMN is_archived BOOLEAN DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='sessions' AND column_name='is_favorite') THEN
    ALTER TABLE sessions ADD COLUMN is_favorite BOOLEAN DEFAULT false;
  END IF;

  -- notes 表补列
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='notes' AND column_name='updated_at') THEN
    ALTER TABLE notes ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();
  END IF;

  -- memories 表补列
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='memories' AND column_name='updated_at') THEN
    ALTER TABLE memories ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();
  END IF;

  -- quick_commands 表补列
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='quick_commands' AND column_name='updated_at') THEN
    ALTER TABLE quick_commands ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();
  END IF;
END $$;

-- ============================================================
-- 3. 索引（IF NOT EXISTS 保证幂等）
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_matrix_user_id ON user_profiles(matrix_user_id);
CREATE INDEX IF NOT EXISTS idx_models_provider ON models(provider);
CREATE INDEX IF NOT EXISTS idx_models_is_active ON models(is_active);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_updated_at ON sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON memories(user_id);
CREATE INDEX IF NOT EXISTS idx_quick_commands_user_id ON quick_commands(user_id);

-- ============================================================
-- 4. RLS 策略（先 DROP 再 CREATE 保证幂等）
-- ============================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE models ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE quick_commands ENABLE ROW LEVEL SECURITY;

-- user_profiles
DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can read own profile" ON user_profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (id = auth.uid());

-- models
DROP POLICY IF EXISTS "Anyone can read active models" ON models;
CREATE POLICY "Anyone can read active models" ON models FOR SELECT USING (is_active = true);

-- sessions
DROP POLICY IF EXISTS "Users can read own sessions" ON sessions;
DROP POLICY IF EXISTS "Users can insert own sessions" ON sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON sessions;
DROP POLICY IF EXISTS "Users can delete own sessions" ON sessions;
CREATE POLICY "Users can read own sessions" ON sessions FOR SELECT USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can insert own sessions" ON sessions FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);
CREATE POLICY "Users can update own sessions" ON sessions FOR UPDATE USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can delete own sessions" ON sessions FOR DELETE USING (user_id::text = auth.uid()::text);

-- notes
DROP POLICY IF EXISTS "Users can read own notes" ON notes;
DROP POLICY IF EXISTS "Users can insert own notes" ON notes;
DROP POLICY IF EXISTS "Users can update own notes" ON notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON notes;
CREATE POLICY "Users can read own notes" ON notes FOR SELECT USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can insert own notes" ON notes FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);
CREATE POLICY "Users can update own notes" ON notes FOR UPDATE USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can delete own notes" ON notes FOR DELETE USING (user_id::text = auth.uid()::text);

-- memories
DROP POLICY IF EXISTS "Users can read own memories" ON memories;
DROP POLICY IF EXISTS "Users can insert own memories" ON memories;
DROP POLICY IF EXISTS "Users can update own memories" ON memories;
CREATE POLICY "Users can read own memories" ON memories FOR SELECT USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can insert own memories" ON memories FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);
CREATE POLICY "Users can update own memories" ON memories FOR UPDATE USING (user_id::text = auth.uid()::text);

-- quick_commands
DROP POLICY IF EXISTS "Users can read own quick_commands" ON quick_commands;
DROP POLICY IF EXISTS "Users can insert own quick_commands" ON quick_commands;
DROP POLICY IF EXISTS "Users can update own quick_commands" ON quick_commands;
DROP POLICY IF EXISTS "Users can delete own quick_commands" ON quick_commands;
CREATE POLICY "Users can read own quick_commands" ON quick_commands FOR SELECT USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can insert own quick_commands" ON quick_commands FOR INSERT WITH CHECK (user_id::text = auth.uid()::text);
CREATE POLICY "Users can update own quick_commands" ON quick_commands FOR UPDATE USING (user_id::text = auth.uid()::text);
CREATE POLICY "Users can delete own quick_commands" ON quick_commands FOR DELETE USING (user_id::text = auth.uid()::text);

-- ============================================================
-- 5. 自动创建用户 Profile 的触发器
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'full_name'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 6. 种子数据：默认 AI 模型
-- ============================================================

INSERT INTO models (id, name, provider, tier, sort_order) VALUES
  ('deepseek-v4-flash', 'DeepSeek V4 Flash', 'deepseek', 'fast', 1),
  ('deepseek-v4-pro', 'DeepSeek V4 Pro', 'deepseek', 'smart', 2),
  ('deepseek-chat', 'DeepSeek Chat (V3.1)', 'deepseek', 'fast', 3),
  ('deepseek-reasoner', 'DeepSeek Reasoner', 'deepseek', 'smart', 4),
  ('gpt-4.1-mini', 'GPT-4.1 Mini', 'openai', 'fast', 5),
  ('gpt-4.1', 'GPT-4.1', 'openai', 'smart', 6),
  ('o4-mini', 'O4 Mini', 'openai', 'smart', 7),
  ('claude-haiku-4-5-20250514', 'Claude Haiku 4.5', 'claude', 'fast', 8),
  ('claude-sonnet-4-20250514', 'Claude Sonnet 4', 'claude', 'smart', 9),
  ('gemini-2.0-flash', 'Gemini 2.0 Flash', 'gemini', 'fast', 10),
  ('gemini-2.5-pro', 'Gemini 2.5 Pro', 'gemini', 'smart', 11)
ON CONFLICT (id) DO NOTHING;
