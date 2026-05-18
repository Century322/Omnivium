# Omnivium 后端架构设计

## 目标：客户端只是壳，所有逻辑在后端

### 架构对比

```
当前（不安全）：
  App ──直接──→ OpenAI/Claude/Gemini API
         ↑ Key 在客户端，可被提取

目标（和微信一样安全）：
  App ──→ Omnivium Backend ──→ OpenAI/Claude/Gemini API
   ↑            ↑                      ↑
  只有UI    所有逻辑+Key           Key永远不出服务器
  短期Token  用户认证+限流
```

---

## 技术栈

| 组件 | 技术选择 | 月成本 | 说明 |
|------|---------|--------|------|
| API 网关 + AI 代理 | Cloudflare Workers | 免费（10万请求/天） | 边缘计算，全球低延迟 |
| 用户认证 | Supabase Auth | 免费（5万MAU） | 邮箱/手机/OAuth |
| 数据库 | Supabase PostgreSQL | 免费（500MB） | 会话/设置/笔记 |
| 实时通信 | Supabase Realtime | 免费 | 跨设备同步 |
| 对象存储 | Cloudflare R2 | ~$0.015/GB | 图片/文件 |
| 推送通知 | Firebase FCM | 免费 | 消息提醒 |
| 域名+SSL | Cloudflare | ~$10/年 | 自动HTTPS |

**总成本：约 $10/年（在免费额度内）**

---

## 后端 API 设计

### 认证

```
POST /auth/register    { email, password } → { user, token }
POST /auth/login       { email, password } → { user, token }
POST /auth/refresh     { refresh_token }   → { token }
POST /auth/logout      { }                  → { ok }
```

### AI 对话（核心）

```
POST /ai/chat          { model, messages, stream } → SSE stream
POST /ai/chat/sync     { model, messages }         → { response }
GET  /ai/models        { }                          → { models[] }
```

**关键：客户端不再持有 API Key，只发 JWT Token，后端根据用户配额选择 Key**

### 会话管理

```
GET    /sessions       → { sessions[] }
POST   /sessions       { title } → { session }
PUT    /sessions/:id   { title, messages }
DELETE /sessions/:id   → { ok }
```

### 笔记/待办/日程

```
GET    /notes          → { notes[] }
POST   /notes          { title, content, type, dueDate }
PUT    /notes/:id      { ... }
DELETE /notes/:id      → { ok }
```

### 用户设置

```
GET    /settings       → { settings }
PUT    /settings       { theme, locale, ... }
```

---

## 数据库 Schema

```sql
-- 用户
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  plan TEXT DEFAULT 'free',  -- free / pro
  monthly_quota INT DEFAULT 100,
  monthly_used INT DEFAULT 0
);

-- AI 会话
CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  model TEXT DEFAULT 'gpt-4o',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 消息
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL,  -- user / assistant / system
  content TEXT NOT NULL,
  tokens_used INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 笔记
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  type TEXT DEFAULT 'text',  -- text / todo / schedule
  is_done BOOLEAN DEFAULT false,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 用户设置
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  theme TEXT DEFAULT 'dark',
  locale TEXT DEFAULT 'zh',
  stt_engine TEXT DEFAULT 'google',
  tts_voice TEXT DEFAULT 'default',
  proxy_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- API Key 池（服务端管理）
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,  -- openai / claude / gemini
  key_encrypted TEXT NOT NULL,
  priority INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  monthly_limit INT,
  monthly_used INT DEFAULT 0
);
```

---

## 安全措施

1. **客户端零 API Key** — 所有 AI 请求走后端，Key 池在服务端轮换
2. **JWT 短期令牌** — 15 分钟过期，自动刷新
3. **SSL Pinning** — 锁定后端域名证书
4. **Rate Limiting** — 每用户每分钟限制请求数
5. **请求签名** — 客户端用 HMAC 签名每个请求
6. **Key 轮换** — 多个 Key 池轮换，单个 Key 泄露不影响全局
7. **审计日志** — 所有 API 调用记录

---

## 迁移步骤

### Phase 1：最小可行后端（1-2 天）
- [x] Cloudflare Worker API 代理（已完成）
- [ ] Supabase 项目创建 + Auth 配置
- [ ] 客户端集成 Supabase Auth

### Phase 2：数据上云（2-3 天）
- [ ] Supabase 数据库 Schema
- [ ] 会话数据同步到云端
- [ ] 笔记/待办数据同步
- [ ] 离线模式支持（本地缓存 + 云端同步）

### Phase 3：安全加固（1-2 天）
- [ ] 移除客户端直连模式
- [ ] JWT Token 自动刷新
- [ ] 请求签名
- [ ] Key 池轮换

### Phase 4：上线（1 天）
- [ ] 内测
- [ ] 提交应用商店
