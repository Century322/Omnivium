const PROVIDERS = {
  openai: { baseUrl: 'https://api.openai.com', pathPrefix: '/v1', authType: 'bearer', format: 'openai' },
  claude: { baseUrl: 'https://api.anthropic.com', pathPrefix: '/v1', authType: 'x-api-key', format: 'claude' },
  gemini: { baseUrl: 'https://generativelanguage.googleapis.com', pathPrefix: '/v1beta', authType: 'query', format: 'gemini' },
  kimi: { baseUrl: 'https://api.moonshot.cn', pathPrefix: '/v1', authType: 'bearer', format: 'openai' },
  deepseek: { baseUrl: 'https://api.deepseek.com', pathPrefix: '/v1', authType: 'bearer', format: 'openai' },
  zhipu: { baseUrl: 'https://open.bigmodel.cn/api/paas', pathPrefix: '/v4', authType: 'bearer', format: 'openai' },
  minimax: { baseUrl: 'https://api.minimax.chat', pathPrefix: '/v1', authType: 'bearer', format: 'openai' },
};

const RATE_LIMITS = {
  free: { rpm: 20, rpd: 500 },
  pro: { rpm: 60, rpd: 2000 },
  enterprise: { rpm: 200, rpd: 10000 },
};

const DEFAULT_MODELS = {
  openai: ['gpt-4.1', 'gpt-4.1-mini', 'gpt-4.1-nano', 'o3', 'o3-mini', 'o4-mini'],
  claude: ['claude-sonnet-4-20250514', 'claude-haiku-4-5-20250514', 'claude-opus-4-20250514'],
  gemini: ['gemini-2.5-pro', 'gemini-2.5-flash', 'gemini-2.0-flash'],
  kimi: ['kimi-k2.5', 'moonshot-v1-128k', 'moonshot-v1-32k'],
  deepseek: ['deepseek-v4-pro', 'deepseek-v4-flash', 'deepseek-chat', 'deepseek-reasoner'],
  zhipu: ['glm-4-plus', 'glm-4-flash', 'glm-4-long', 'glm-4.5v'],
  minimax: ['MiniMax-Text-01', 'abab6.5s-chat'],
};

const REMOTE_CONFIG_DEFAULTS = {
  maintenance_mode: false,
  min_app_version: '1.0.0',
  force_update: false,
  ai_proxy_enabled: true,
  intent_classification_enabled: true,
  intent_classification_provider: 'openai',
  intent_classification_model: 'gpt-4o-mini',
  max_context_messages: 50,
  stream_chunk_throttle_ms: 0,
  features: {
    voice_chat: true,
    web_search: true,
    file_manager: true,
    quick_commands: true,
    notes: true,
  },
};

function corsHeaders(origin) {
  const allowedOrigins = [
    'https://omnivium.app',
    'https://omnivium-web.pages.dev',
    'capacitor://localhost',
    'http://localhost',
    'http://localhost:5000',
    'http://localhost:8080',
  ];
  const requestOrigin = origin || '';
  const allowOrigin = allowedOrigins.includes(requestOrigin) ? requestOrigin : allowedOrigins[0];
  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Request-Signature, X-Timestamp, X-Device-Id, X-App-Version, X-Platform, X-Auth-Source, X-User-Id',
  };
}

function jsonResponse(data, status = 200, extraHeaders = {}, origin = '') {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders(origin), ...extraHeaders },
  });
}

function base64UrlDecode(str) {
  let base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  while (base64.length % 4) base64 += '=';
  return atob(base64);
}

function base64UrlEncode(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function importPublicKey(pem) {
  const pemBody = pem.replace(/-----BEGIN.*?-----/g, '').replace(/-----END.*?-----/g, '').replace(/\s/g, '');
  const binaryStr = atob(pemBody);
  const bytes = new Uint8Array(binaryStr.length);
  for (let i = 0; i < binaryStr.length; i++) bytes[i] = binaryStr.charCodeAt(i);
  return await crypto.subtle.importKey('spki', bytes, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
}

async function verifyJwtSignature(token, publicKey) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  try {
    const header = JSON.parse(base64UrlDecode(parts[0]));
    if (header.alg !== 'RS256') return null;
    const payload = JSON.parse(base64UrlDecode(parts[1]));
    if (payload.exp && payload.exp < Date.now() / 1000) return null;
    if (payload.iss && payload.iss !== 'omnivium.app' && payload.iss !== 'https://omnivium.app') return null;
    const signatureInput = new TextEncoder().encode(parts[0] + '.' + parts[1]);
    const signatureBytes = new Uint8Array(Array.from(base64UrlDecode(parts[2]), c => c.charCodeAt(0)));
    const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', publicKey, signatureBytes, signatureInput);
    return valid ? payload : null;
  } catch { return null; }
}

async function authenticate(request, env) {
  const timestamp = request.headers.get('X-Timestamp');
  if (!timestamp) return null;
  const now = Date.now();
  const ts = parseInt(timestamp);
  if (isNaN(ts) || Math.abs(now - ts) > 300000) return null;

  const auth = request.headers.get('Authorization');
  if (!auth || !auth.startsWith('Bearer ')) return null;
  const token = auth.substring(7);

  if (token === env.PROXY_TOKEN) return { id: 'proxy', plan: 'enterprise' };

  try {
    const parts = token.split('.');
    if (parts.length === 3) {
      if (env.JWT_PUBLIC_KEY) {
        const publicKey = await importPublicKey(env.JWT_PUBLIC_KEY);
        const payload = await verifyJwtSignature(token, publicKey);
        if (!payload) return null;
        return { id: payload.sub || payload.user_id, plan: payload.plan || 'free' };
      }
      return null;
    }
  } catch {}

  if (token.startsWith('syt_') || token.startsWith('MDA')) {
    const authSource = request.headers.get('X-Auth-Source');
    if (authSource === 'matrix') {
      const userId = request.headers.get('X-User-Id') || 'matrix_user';
      const verified = await verifyMatrixToken(token, userId, env);
      if (!verified) return null;
      return { id: userId, plan: 'free' };
    }
  }

  return null;
}

async function verifySrpProof(proof, srpId, verifier, salt) {
  try {
    const proofHash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(`${proof}:${srpId}:${verifier}:${salt}`));
    const proofHex = Array.from(new Uint8Array(proofHash)).map(b => b.toString(16).padStart(2, '0')).join('');
    const verifierHash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
    const verifierHex = Array.from(new Uint8Array(verifierHash)).map(b => b.toString(16).padStart(2, '0')).join('');
    return proofHex.substring(0, 32) === verifierHex.substring(0, 32);
  } catch (e) {
    return false;
  }
}

async function verifyMatrixToken(token, claimedUserId, env) {
  const homeserver = env.MATRIX_HOMESERVER || 'https://matrix.omnivium.app';
  const cacheKey = `matrix_auth:${token.slice(-16)}`;
  try {
    const cached = await env.KV?.get(cacheKey);
    if (cached === claimedUserId) return true;
  } catch {}
  try {
    const resp = await fetch(`${homeserver}/_matrix/client/v3/account/whoami`, {
      headers: { 'Authorization': `Bearer ${token}` },
      signal: AbortSignal.timeout(5000),
    });
    if (!resp.ok) return false;
    const data = await resp.json();
    if (data.user_id !== claimedUserId) return false;
    try {
      await env.KV?.put(cacheKey, claimedUserId, { expirationTtl: 300 });
    } catch {}
    return true;
  } catch {
    return false;
  }
}

async function checkRateLimit(userId, plan, env) {
  const limits = RATE_LIMITS[plan] || RATE_LIMITS.free;
  const minuteKey = `rate:${userId}:${Math.floor(Date.now() / 60000)}`;
  const dayKey = `rate:${userId}:${Math.floor(Date.now() / 86400000)}`;

  const rpmCount = parseInt(await env.KV?.get(minuteKey) || '0');
  if (rpmCount >= limits.rpm) return { allowed: false, reason: 'rpm_exceeded' };

  const rpdCount = parseInt(await env.KV?.get(dayKey) || '0');
  if (rpdCount >= limits.rpd) return { allowed: false, reason: 'rpd_exceeded' };

  await env.KV?.put(minuteKey, String(rpmCount + 1), { expirationTtl: 120 });
  await env.KV?.put(dayKey, String(rpdCount + 1), { expirationTtl: 86400 });

  return { allowed: true, remaining: { rpm: limits.rpm - rpmCount - 1, rpd: limits.rpd - rpdCount - 1 } };
}

function getApiKey(provider, env) {
  const keyMap = {
    openai: env.OPENAI_API_KEY,
    claude: env.ANTHROPIC_API_KEY,
    gemini: env.GEMINI_API_KEY,
    kimi: env.KIMI_API_KEY,
    deepseek: env.DEEPSEEK_API_KEY,
    zhipu: env.ZHIPU_API_KEY,
    minimax: env.MINIMAX_API_KEY,
  };
  const keys = (keyMap[provider] || '').split(',').filter(Boolean);
  if (keys.length === 0) return null;
  return keys[Math.floor(Math.random() * keys.length)];
}

function detectProvider(model, clientProvider) {
  if (clientProvider && PROVIDERS[clientProvider]) return clientProvider;
  const modelLower = (model || '').toLowerCase();
  if (modelLower.includes('claude') || modelLower.includes('anthropic')) return 'claude';
  if (modelLower.includes('gemini')) return 'gemini';
  if (modelLower.includes('kimi') || modelLower.includes('moonshot')) return 'kimi';
  if (modelLower.includes('deepseek')) return 'deepseek';
  if (modelLower.includes('glm') || modelLower.includes('chatglm')) return 'zhipu';
  if (modelLower.includes('minimax') || modelLower.includes('abab')) return 'minimax';
  return 'openai';
}

function convertToClaudeRequest(body) {
  const messages = (body.messages || []).map(m => {
    if (m.role === 'system') return { role: 'user', content: m.content };
    return { role: m.role, content: m.content };
  });

  const systemMsg = (body.messages || []).find(m => m.role === 'system');

  const req = {
    model: body.model,
    messages,
    max_tokens: body.max_tokens || 4096,
    stream: body.stream || false,
  };

  if (systemMsg) req.system = systemMsg.content;
  if (body.temperature !== undefined) req.temperature = body.temperature;

  return req;
}

function convertToGeminiRequest(body) {
  const contents = (body.messages || [])
    .filter(m => m.role !== 'system')
    .map(m => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));

  const req = {
    contents,
    generationConfig: {
      maxOutputTokens: body.max_tokens || 4096,
    },
  };

  if (body.temperature !== undefined) req.generationConfig.temperature = body.temperature;

  const systemMsg = (body.messages || []).find(m => m.role === 'system');
  if (systemMsg) {
    req.systemInstruction = { parts: [{ text: systemMsg.content }] };
  }

  return req;
}

function convertClaudeResponseToOpenAI(claudeResp, model) {
  const content = (claudeResp.content || []).map(c => c.text || '').join('');
  return {
    id: `chatcmpl-${Date.now()}`,
    object: 'chat.completion',
    created: Math.floor(Date.now() / 1000),
    model: claudeResp.model || model,
    choices: [{
      index: 0,
      message: { role: 'assistant', content },
      finish_reason: claudeResp.stop_reason === 'end_turn' ? 'stop' : claudeResp.stop_reason || 'stop',
    }],
    usage: {
      prompt_tokens: claudeResp.usage?.input_tokens || 0,
      completion_tokens: claudeResp.usage?.output_tokens || 0,
      total_tokens: (claudeResp.usage?.input_tokens || 0) + (claudeResp.usage?.output_tokens || 0),
    },
  };
}

function convertGeminiResponseToOpenAI(geminiResp, model) {
  const content = (geminiResp.candidates || [])
    .flatMap(c => (c.content?.parts || []).map(p => p.text || ''))
    .join('');
  return {
    id: `chatcmpl-${Date.now()}`,
    object: 'chat.completion',
    created: Math.floor(Date.now() / 1000),
    model,
    choices: [{
      index: 0,
      message: { role: 'assistant', content },
      finish_reason: 'stop',
    }],
    usage: {
      prompt_tokens: geminiResp.usageMetadata?.promptTokenCount || 0,
      completion_tokens: geminiResp.usageMetadata?.candidatesTokenCount || 0,
      total_tokens: geminiResp.usageMetadata?.totalTokenCount || 0,
    },
  };
}

async function handleAIChat(request, env, user) {
  const body = await request.json();
  const { model, messages, stream = true, provider: clientProvider, temperature, max_tokens, agent_mode, skills } = body;

  if (agent_mode && stream) {
    return handleAgentMode(body, env, user);
  }

  const provider = detectProvider(model, clientProvider);
  const config = PROVIDERS[provider];
  if (!config) return jsonResponse({ error: `Unknown provider: ${provider}` }, 400);

  const apiKey = getApiKey(provider, env);
  if (!apiKey) return jsonResponse({ error: `Service unavailable for: ${provider}`, code: 'PROVIDER_UNCONFIGURED' }, 503);

  const chatBody = { model, messages, stream: !!stream };
  if (temperature !== undefined) chatBody.temperature = temperature;
  if (max_tokens !== undefined) chatBody.max_tokens = max_tokens;

  if (config.format === 'claude') {
    return handleClaudeChat(chatBody, apiKey, stream);
  } else if (config.format === 'gemini') {
    return handleGeminiChat(chatBody, apiKey, stream);
  } else {
    return handleOpenAICompatibleChat(provider, chatBody, apiKey, stream);
  }
}

async function handleAgentMode(body, env, user) {
  const { model, messages, provider: clientProvider, temperature, max_tokens, skills } = body;
  const provider = detectProvider(model, clientProvider);
  const apiKey = getApiKey(provider, env);
  if (!apiKey) return jsonResponse({ error: `Service unavailable for: ${provider}`, code: 'PROVIDER_UNCONFIGURED' }, 503);

  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      const send = (event, data) => {
        controller.enqueue(encoder.encode(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));
      };

      try {
        send('agent_status', { phase: 'classifying', message: 'Analyzing intent...' });

        const lastUserMsg = [...messages].reverse().find(m => m.role === 'user');
        const userInput = lastUserMsg?.content || '';

        const memoryContext = await getMemoryContext(user.id, userInput, env);
        if (memoryContext) {
          const hasSystem = messages.findIndex(m => m.role === 'system');
          if (hasSystem >= 0) {
            messages[hasSystem].content += '\n\n' + memoryContext;
          } else {
            messages.unshift({ role: 'system', content: memoryContext });
          }
          send('agent_memory', { found: true });
        }

        const remoteConfig = await getRemoteConfig(env);
        let intentResult = { channel: 'fast', intent: 'chat', entities: {}, confidence: 1.0 };

        if (remoteConfig.intent_classification_enabled && userInput) {
          try {
            const classifyProvider = detectProvider(remoteConfig.intent_classification_model || 'gpt-4o-mini');
            const classifyApiKey = getApiKey(classifyProvider, env);
            if (classifyApiKey) {
              const skillDescriptions = (skills || []).map(s =>
                `- id: ${s.id}, name: ${s.name}, desc: ${s.description}, channel: ${s.channel}`
              ).join('\n');

              const classifySystemPrompt = `Classify the user's intent. Available skills:\n${skillDescriptions || 'None'}\n\nRespond JSON: {"channel":"fast"|"slow"|"mixed","intent":"chat"|"skill_call","entities":{},"confidence":0.0-1.0}\nDefault to "fast"/"chat" if unsure.`;

              const classifyBody = {
                model: remoteConfig.intent_classification_model || 'gpt-4o-mini',
                messages: [
                  { role: 'system', content: classifySystemPrompt },
                  { role: 'user', content: userInput },
                ],
                temperature: 0.1,
                max_tokens: 256,
                stream: false,
              };

              const classifyResp = await handleOpenAICompatibleChat(classifyProvider, classifyBody, classifyApiKey, false);
              if (classifyResp.status === 200) {
                const text = await classifyResp.text();
                const json = JSON.parse(text);
                const content = json['choices']?.[0]?.['message']?.['content'] || '';
                intentResult = JSON.parse(content);
              }
            }
          } catch (e) {}
        }

        send('agent_intent', intentResult);

        if (intentResult.channel === 'slow' && intentResult.entities?.skillId === 'web_search') {
          send('agent_status', { phase: 'executing_skill', skill: 'web_search' });
          try {
            const searchResult = await executeWebSearch(intentResult.entities.q || userInput, env);
            send('agent_skill_result', { skill: 'web_search', success: true, data: searchResult });
            const searchContext = JSON.stringify(searchResult);
            messages.push({ role: 'system', content: `Web search results:\n${searchContext}` });
          } catch (e) {
            send('agent_skill_result', { skill: 'web_search', success: false, error: e.message });
          }
        }

        send('agent_status', { phase: 'generating', message: 'Generating response...' });

        const chatBody = { model, messages, stream: true };
        if (temperature !== undefined) chatBody.temperature = temperature;
        if (max_tokens !== undefined) chatBody.max_tokens = max_tokens;

        const config = PROVIDERS[provider];
        let aiResponse;
        if (config.format === 'claude') {
          aiResponse = await handleClaudeChat(chatBody, apiKey, true);
        } else if (config.format === 'gemini') {
          aiResponse = await handleGeminiChat(chatBody, apiKey, true);
        } else {
          aiResponse = await handleOpenAICompatibleChat(provider, chatBody, apiKey, true);
        }

        const reader = aiResponse.body.getReader();
        const decoder = new TextDecoder();
        let fullContent = '';

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split('\n');
          for (const line of lines) {
            if (line.startsWith('data: ') && line.trim() !== 'data: [DONE]') {
              try {
                const data = JSON.parse(line.substring(6));
                const content = data.choices?.[0]?.delta?.content || '';
                if (content) fullContent += content;
                controller.enqueue(encoder.encode(`data: ${JSON.stringify(data)}\n\n`));
              } catch {}
            }
          }
        }

        send('agent_status', { phase: 'completed', message: 'Done' });

        if (fullContent && user.id) {
          try {
            const extractPatterns = [
              { regex: /(?:我叫|我的名字是|我是|My name is|I am)\s*([^\s,，。.！!？?]{1,20})/gi, category: 'name', importance: 0.9 },
              { regex: /(?:我在|我住在|I live in|I'm in)\s*([^\s,，。.！!？?]{1,30})/gi, category: 'location', importance: 0.7 },
              { regex: /(?:我喜欢|我爱|I like|I love|I prefer)\s*([^\s,，。.！!？?]{1,50})/gi, category: 'preference', importance: 0.8 },
              { regex: /(?:我不喜欢|我讨厌|I don't like|I hate)\s*([^\s,，。.！!？?]{1,50})/gi, category: 'dislike', importance: 0.8 },
            ];
            for (const pattern of extractPatterns) {
              const matches = [...userInput.matchAll(pattern.regex)];
              for (const match of matches) {
                await handleMemoryStore(user.id, { json: () => Promise.resolve({ content: match[1], category: pattern.category, importance: pattern.importance }) }, env);
              }
            }
          } catch (e) {}
        }

        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
      } catch (e) {
        send('agent_error', { error: e.message });
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
      }
    },
  });

  return new Response(stream, {
    status: 200,
    headers: {
      ...corsHeaders(),
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'X-Accel-Buffering': 'no',
    },
  });
}

async function executeWebSearch(query, env) {
  const serperKey = env.SERPER_API_KEY;
  if (!serperKey) throw new Error('Search not configured');

  const resp = await fetch('https://google.serper.dev/search', {
    method: 'POST',
    headers: { 'X-API-KEY': serperKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ q: query, gl: 'cn', hl: 'zh-cn' }),
  });
  return await resp.json();
}

async function handleMemoryGet(userId, request, env) {
  const url = new URL(request.url);
  const query = url.searchParams.get('q') || '';
  const key = `memory:${userId}`;

  try {
    const raw = await env.KV?.get(key);
    if (!raw) return jsonResponse({ memories: [] });

    const memories = JSON.parse(raw);
    if (!query) return jsonResponse({ memories: memories.slice(0, 20) });

    const queryLower = query.toLowerCase();
    const scored = memories.map(m => {
      let score = 0;
      if (m.content.toLowerCase().includes(queryLower)) score += 2;
      if (m.category && m.category.toLowerCase().includes(queryLower)) score += 1;
      score += (m.importance || 0.5) * 0.5;
      return { ...m, score };
    }).filter(m => m.score > 0).sort((a, b) => b.score - a.score);

    return jsonResponse({ memories: scored.slice(0, 10) });
  } catch (e) {
    return jsonResponse({ memories: [] });
  }
}

async function handleMemoryStore(userId, request, env) {
  const body = await request.json();
  const { content, category, importance } = body;

  if (!content) return jsonResponse({ error: 'Content required' }, 400);

  const key = `memory:${userId}`;

  try {
    const raw = await env.KV?.get(key);
    const memories = raw ? JSON.parse(raw) : [];

    memories.push({
      id: `mem_${Date.now()}`,
      content,
      category: category || 'fact',
      importance: importance || 0.5,
      createdAt: new Date().toISOString(),
    });

    const maxMemories = 200;
    if (memories.length > maxMemories) {
      memories.sort((a, b) => (b.importance || 0) - (a.importance || 0));
      memories.length = maxMemories;
    }

    await env.KV?.put(key, JSON.stringify(memories));
    return jsonResponse({ success: true });
  } catch (e) {
    return jsonResponse({ error: 'Memory store failed' }, 500);
  }
}

async function getMemoryContext(userId, query, env) {
  const key = `memory:${userId}`;
  try {
    const raw = await env.KV?.get(key);
    if (!raw) return '';

    const memories = JSON.parse(raw);
    if (memories.length === 0) return '';

    const queryLower = (query || '').toLowerCase();
    const relevant = memories
      .map(m => {
        let score = (m.importance || 0.5);
        if (queryLower && m.content.toLowerCase().includes(queryLower)) score += 2;
        return { ...m, score };
      })
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    if (relevant.length === 0) return '';

    const contextLines = relevant.map(m => `- [${m.category || 'fact'}] ${m.content}`).join('\n');
    return `[User Memory]\n${contextLines}`;
  } catch (e) {
    return '';
  }
}

async function handleOpenAICompatibleChat(provider, chatBody, apiKey, stream) {
  const config = PROVIDERS[provider];
  const targetUrl = `${config.baseUrl}${config.pathPrefix}/chat/completions`;
  const headers = { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` };

  if (stream) {
    const response = await fetch(targetUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(chatBody),
    });

    if (!response.ok) {
      const errText = await response.text();
      return jsonResponse({ error: `Upstream error: ${response.status}`, details: errText }, response.status);
    }

    return new Response(response.body, {
      status: 200,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    });
  }

  const response = await fetch(targetUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify(chatBody),
  });

  const text = await response.text();
  return new Response(text, {
    status: response.status,
    headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
  });
}

async function handleClaudeChat(chatBody, apiKey, stream) {
  const claudeBody = convertToClaudeRequest(chatBody);
  const targetUrl = 'https://api.anthropic.com/v1/messages';
  const headers = {
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
  };

  if (stream) {
    claudeBody.stream = true;
    const response = await fetch(targetUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(claudeBody),
    });

    if (!response.ok) {
      const errText = await response.text();
      return jsonResponse({ error: `Claude error: ${response.status}`, details: errText }, response.status);
    }

    const transformedStream = transformClaudeSSE(response.body, chatBody.model);
    return new Response(transformedStream, {
      status: 200,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    });
  }

  const response = await fetch(targetUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify(claudeBody),
  });

  const text = await response.text();
  if (!response.ok) {
    return jsonResponse({ error: `Claude error: ${response.status}`, details: text }, response.status);
  }

  const claudeResp = JSON.parse(text);
  const openaiResp = convertClaudeResponseToOpenAI(claudeResp, chatBody.model);
  return jsonResponse(openaiResp);
}

function transformClaudeSSE(readable, model) {
  const reader = readable.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();

  return new ReadableStream({
    async pull(controller) {
      try {
        const { done, value } = await reader.read();
        if (done) {
          controller.enqueue(encoder.encode('data: [DONE]\n\n'));
          controller.close();
          return;
        }

        const chunk = decoder.decode(value, { stream: true });
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (!line.startsWith('data: ')) continue;
          const data = line.substring(6).trim();
          if (!data) continue;

          try {
            const event = JSON.parse(data);

            if (event.type === 'content_block_delta' && event.delta?.type === 'text_delta') {
              const openaiChunk = {
                id: `chatcmpl-${Date.now()}`,
                object: 'chat.completion.chunk',
                created: Math.floor(Date.now() / 1000),
                model: model,
                choices: [{
                  index: 0,
                  delta: { content: event.delta.text },
                  finish_reason: null,
                }],
              };
              controller.enqueue(encoder.encode(`data: ${JSON.stringify(openaiChunk)}\n\n`));
            } else if (event.type === 'message_stop') {
              const openaiChunk = {
                id: `chatcmpl-${Date.now()}`,
                object: 'chat.completion.chunk',
                created: Math.floor(Date.now() / 1000),
                model: model,
                choices: [{
                  index: 0,
                  delta: {},
                  finish_reason: 'stop',
                }],
              };
              controller.enqueue(encoder.encode(`data: ${JSON.stringify(openaiChunk)}\n\n`));
            } else if (event.type === 'message_start' || event.type === 'content_block_start' || event.type === 'content_block_stop' || event.type === 'ping') {
              // skip
            } else if (event.type === 'message_delta' && event.delta?.stop_reason) {
              const openaiChunk = {
                id: `chatcmpl-${Date.now()}`,
                object: 'chat.completion.chunk',
                created: Math.floor(Date.now() / 1000),
                model: model,
                choices: [{
                  index: 0,
                  delta: {},
                  finish_reason: event.delta.stop_reason === 'end_turn' ? 'stop' : event.delta.stop_reason,
                }],
              };
              controller.enqueue(encoder.encode(`data: ${JSON.stringify(openaiChunk)}\n\n`));
            }
          } catch {}
        }
      } catch (e) {
        controller.close();
      }
    },
    cancel() {
      reader.cancel();
    },
  });
}

async function handleGeminiChat(chatBody, apiKey, stream) {
  const geminiBody = convertToGeminiRequest(chatBody);
  const action = stream ? 'streamGenerateContent' : 'generateContent';
  const targetUrl = `https://generativelanguage.googleapis.com/v1beta/models/${chatBody.model}:${action}?key=${apiKey}`;
  const headers = { 'Content-Type': 'application/json' };

  if (stream) {
    const response = await fetch(targetUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify(geminiBody),
    });

    if (!response.ok) {
      const errText = await response.text();
      return jsonResponse({ error: `Gemini error: ${response.status}`, details: errText }, response.status);
    }

    const transformedStream = transformGeminiSSE(response.body, chatBody.model);
    return new Response(transformedStream, {
      status: 200,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    });
  }

  const response = await fetch(targetUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify(geminiBody),
  });

  const text = await response.text();
  if (!response.ok) {
    return jsonResponse({ error: `Gemini error: ${response.status}`, details: text }, response.status);
  }

  const geminiResp = JSON.parse(text);
  const openaiResp = convertGeminiResponseToOpenAI(geminiResp, chatBody.model);
  return jsonResponse(openaiResp);
}

function transformGeminiSSE(readable, model) {
  const reader = readable.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  let buffer = '';

  return new ReadableStream({
    async pull(controller) {
      try {
        const { done, value } = await reader.read();
        if (done) {
          controller.enqueue(encoder.encode('data: [DONE]\n\n'));
          controller.close();
          return;
        }

        buffer += decoder.decode(value, { stream: true });

        const parts = buffer.split(/(?<=\}),\s*(?=\{)/);
        buffer = parts.pop() || '';

        for (const part of parts) {
          try {
            const geminiChunk = JSON.parse(part.trim());
            const text = (geminiChunk.candidates || [])
              .flatMap(c => (c.content?.parts || []).map(p => p.text || ''))
              .join('');

            if (text) {
              const openaiChunk = {
                id: `chatcmpl-${Date.now()}`,
                object: 'chat.completion.chunk',
                created: Math.floor(Date.now() / 1000),
                model: model,
                choices: [{
                  index: 0,
                  delta: { content: text },
                  finish_reason: null,
                }],
              };
              controller.enqueue(encoder.encode(`data: ${JSON.stringify(openaiChunk)}\n\n`));
            }
          } catch {}
        }
      } catch (e) {
        controller.close();
      }
    },
    cancel() {
      reader.cancel();
    },
  });
}

async function proxyAIRequest(provider, path, request, env) {
  const config = PROVIDERS[provider];
  if (!config) return jsonResponse({ error: `Unknown provider: ${provider}` }, 400);

  const apiKey = getApiKey(provider, env);
  if (!apiKey) return jsonResponse({ error: `Service unavailable for: ${provider}`, code: 'PROVIDER_UNCONFIGURED' }, 503);

  const targetUrl = `${config.baseUrl}${config.pathPrefix}${path}`;
  const headers = new Headers(request.headers);
  headers.delete('Authorization');
  headers.delete('X-Request-Signature');
  headers.delete('X-Timestamp');
  headers.delete('X-Device-Id');
  headers.delete('X-App-Version');
  headers.delete('X-Platform');
  headers.delete('X-Auth-Source');
  headers.delete('X-User-Id');
  headers.delete('host');

  if (config.authType === 'x-api-key') {
    headers.set('x-api-key', apiKey);
    headers.set('anthropic-version', '2023-06-01');
  } else if (config.authType === 'query') {
    const url = new URL(targetUrl);
    url.searchParams.set('key', apiKey);
    return fetchWithStream(new Request(url.toString(), { method: request.method, headers, body: request.body }));
  } else {
    headers.set('Authorization', `Bearer ${apiKey}`);
  }

  return fetchWithStream(new Request(targetUrl, { method: request.method, headers, body: request.body }));
}

async function fetchWithStream(proxyReq) {
  const response = await fetch(proxyReq);
  const contentType = response.headers.get('Content-Type') || 'application/json';

  if (contentType.includes('text/event-stream')) {
    return new Response(response.body, {
      status: response.status,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
      },
    });
  }

  const body = await response.text();
  return new Response(body, {
    status: response.status,
    headers: { ...corsHeaders(), 'Content-Type': contentType },
  });
}

function handleModels(env) {
  const models = [];

  if (env.DEEPSEEK_API_KEY) {
    models.push(
      { id: 'deepseek-v4-flash', name: 'DeepSeek V4 Flash', provider: 'deepseek', tier: 'fast' },
      { id: 'deepseek-v4-pro', name: 'DeepSeek V4 Pro', provider: 'deepseek', tier: 'smart' },
      { id: 'deepseek-chat', name: 'DeepSeek Chat (V3.1)', provider: 'deepseek', tier: 'fast' },
      { id: 'deepseek-reasoner', name: 'DeepSeek Reasoner', provider: 'deepseek', tier: 'smart' },
    );
  }
  if (env.OPENAI_API_KEY) {
    models.push(
      { id: 'gpt-4.1-mini', name: 'GPT-4.1 Mini', provider: 'openai', tier: 'fast' },
      { id: 'gpt-4.1', name: 'GPT-4.1', provider: 'openai', tier: 'smart' },
      { id: 'o4-mini', name: 'O4 Mini', provider: 'openai', tier: 'smart' },
    );
  }
  if (env.ANTHROPIC_API_KEY) {
    models.push(
      { id: 'claude-haiku-4-5-20250514', name: 'Claude Haiku 4.5', provider: 'claude', tier: 'fast' },
      { id: 'claude-sonnet-4-20250514', name: 'Claude Sonnet 4', provider: 'claude', tier: 'smart' },
    );
  }
  if (env.GEMINI_API_KEY) {
    models.push(
      { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash', provider: 'gemini', tier: 'fast' },
      { id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', provider: 'gemini', tier: 'smart' },
    );
  }
  if (env.KIMI_API_KEY) {
    models.push(
      { id: 'moonshot-v1-32k', name: 'Moonshot V1 32K', provider: 'kimi', tier: 'fast' },
      { id: 'kimi-k2.5', name: 'Kimi K2.5', provider: 'kimi', tier: 'smart' },
    );
  }
  if (env.ZHIPU_API_KEY) {
    models.push(
      { id: 'glm-4-flash', name: 'GLM-4 Flash', provider: 'zhipu', tier: 'fast' },
      { id: 'glm-4-plus', name: 'GLM-4 Plus', provider: 'zhipu', tier: 'smart' },
    );
  }
  if (env.MINIMAX_API_KEY) {
    models.push(
      { id: 'abab6.5s-chat', name: 'ABAB 6.5S', provider: 'minimax', tier: 'fast' },
      { id: 'MiniMax-Text-01', name: 'MiniMax Text 01', provider: 'minimax', tier: 'smart' },
    );
  }

  return jsonResponse({ models });
}

async function handleSearch(request, env) {
  const body = await request.json();
  const { q } = body;
  if (!q) return jsonResponse({ error: 'Query required' }, 400);

  const serperKey = env.SERPER_API_KEY;
  if (!serperKey) return jsonResponse({ error: 'Search not configured' }, 503);

  try {
    const resp = await fetch('https://google.serper.dev/search', {
      method: 'POST',
      headers: { 'X-API-KEY': serperKey, 'Content-Type': 'application/json' },
      body: JSON.stringify({ q, gl: 'cn', hl: 'zh-cn' }),
    });
    const data = await resp.json();
    return jsonResponse(data);
  } catch (e) {
    return jsonResponse({ error: 'Search failed' }, 500);
  }
}

async function handleIntentClassification(request, env) {
  const body = await request.json();
  const { input, skills, model } = body;

  const config = await getRemoteConfig(env);
  if (!config.intent_classification_enabled) {
    return jsonResponse({ channel: 'fast', intent: 'chat', entities: {}, confidence: 1.0 });
  }

  const provider = detectProvider(config.intent_classification_model || model || 'gpt-4o-mini');
  const classifyModel = config.intent_classification_model || model || 'gpt-4o-mini';

  const skillDescriptions = (skills || []).map(s =>
    `- id: ${s.id}, name: ${s.name}, desc: ${s.description}, channel: ${s.channel}, permission: ${s.permission}`
  ).join('\n');

  const systemPrompt = `You are OMNI, the AI assistant for Omnivium. Classify the user's intent.

Available skills:
${skillDescriptions || 'No skills available.'}

Respond in JSON format:
{
  "channel": "fast" | "slow" | "mixed",
  "intent": "chat" | "skill_call",
  "entities": {"skillId": "..." (if skill_call)},
  "confidence": 0.0-1.0
}

Rules:
- "fast": pure text conversation, no tool needed
- "slow": needs to call a tool/skill (search, add friend, etc.)
- "mixed": needs both text response AND tool call
- Only set skillId if the user clearly wants to use a specific skill
- Default to "fast" / "chat" if unsure`;

  const classifyBody = {
    model: classifyModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: input },
    ],
    temperature: 0.1,
    max_tokens: 256,
    stream: false,
  };

  try {
    const response = await handleOpenAICompatibleChat(provider, classifyBody, getApiKey(provider, env), false);
    if (response.status !== 200) {
      return jsonResponse({ channel: 'fast', intent: 'chat', entities: {}, confidence: 0.5 });
    }
    const text = await response.text();
    const json = JSON.parse(text);
    const content = json['choices']?.[0]?.['message']?.['content'] || '';
    const result = JSON.parse(content);
    return jsonResponse({
      channel: result.channel || 'fast',
      intent: result.intent || 'chat',
      entities: result.entities || {},
      confidence: result.confidence || 0.5,
    });
  } catch (e) {
    return jsonResponse({ channel: 'fast', intent: 'chat', entities: {}, confidence: 0.5 });
  }
}

async function getRemoteConfig(env) {
  try {
    const cached = await env.KV?.get('remote_config');
    if (cached) return { ...REMOTE_CONFIG_DEFAULTS, ...JSON.parse(cached) };
  } catch {}
  return { ...REMOTE_CONFIG_DEFAULTS };
}

async function handleRemoteConfig(request, env) {
  const config = await getRemoteConfig(env);
  return jsonResponse({ config });
}

async function handleRegisterDevice(request, env) {
  const body = await request.json();
  const { device_id, platform, fcm_token, app_version, user_id } = body;

  if (!device_id || !fcm_token) {
    return jsonResponse({ error: 'device_id and fcm_token are required' }, 400);
  }

  const key = `device:${device_id}`;
  await env.KV?.put(key, JSON.stringify({
    device_id,
    platform: platform || 'unknown',
    fcm_token,
    app_version: app_version || '1.0.0',
    user_id: user_id || null,
    registered_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  }));

  return jsonResponse({ success: true, device_id });
}

async function handleAppStatus(request, env) {
  const config = await getRemoteConfig(env);
  const url = new URL(request.url);
  const appVersion = request.headers.get('X-App-Version') || url.searchParams.get('version') || '1.0.0';

  const needsUpdate = config.force_update && compareVersions(config.min_app_version, appVersion) > 0;

  return jsonResponse({
    status: config.maintenance_mode ? 'maintenance' : 'ok',
    version: '3.0.0',
    min_app_version: config.min_app_version,
    force_update: needsUpdate,
    providers: Object.keys(PROVIDERS),
    features: config.features,
  });
}

function compareVersions(a, b) {
  const pa = a.split('.').map(Number);
  const pb = b.split('.').map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const na = pa[i] || 0;
    const nb = pb[i] || 0;
    if (na > nb) return 1;
    if (na < nb) return -1;
  }
  return 0;
}

async function handleUISchemas(request, env) {
  try {
    const cached = await env.KV?.get('ui_schemas');
    if (cached) {
      return jsonResponse({ schemas: JSON.parse(cached) });
    }
  } catch {}
  return jsonResponse({ schemas: {} });
}

async function handleReflection(request, env) {
  const body = await request.json();
  const { answer, original_question, model } = body;

  const provider = detectProvider(model || 'gpt-4o-mini');
  const reflectModel = model || 'gpt-4o-mini';
  const apiKey = getApiKey(provider, env);
  if (!apiKey) return jsonResponse({ quality_score: 0.8, is_complete: true, missing_aspects: [], suggestion: '' });

  const systemPrompt = `You are a quality assurance AI. Evaluate the following answer for completeness and accuracy.

Original question: ${original_question}
Answer to evaluate: ${answer}

Respond in JSON format:
{
  "quality_score": 0.0-1.0,
  "is_complete": true/false,
  "missing_aspects": ["..."],
  "suggestion": "..." (empty string if answer is good)
}

Be strict but fair. Only flag genuinely incomplete or inaccurate answers.`;

  const reflectBody = {
    model: reflectModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: 'Evaluate this answer.' },
    ],
    temperature: 0.1,
    max_tokens: 256,
    stream: false,
  };

  try {
    const response = await handleOpenAICompatibleChat(provider, reflectBody, apiKey, false);
    if (response.status !== 200) {
      return jsonResponse({ quality_score: 0.8, is_complete: true, missing_aspects: [], suggestion: '' });
    }
    const text = await response.text();
    const json = JSON.parse(text);
    const content = json['choices']?.[0]?.['message']?.['content'] || '';
    const result = JSON.parse(content);
    return jsonResponse(result);
  } catch (e) {
    return jsonResponse({ quality_score: 0.8, is_complete: true, missing_aspects: [], suggestion: '' });
  }
}

async function handleMultiStepPlan(request, env) {
  const body = await request.json();
  const { task, model, available_tools } = body;

  const provider = detectProvider(model || 'gpt-4o');
  const planModel = model || 'gpt-4o';
  const apiKey = getApiKey(provider, env);
  if (!apiKey) return jsonResponse({ steps: [{ id: 1, action: 'respond', reasoning: 'Direct response', expected_output: 'Answer' }], estimated_rounds: 1, requires_user_input: false });

  const toolList = (available_tools || []).map(t => `- ${t.id}: ${t.name} - ${t.description}`).join('\n');

  const systemPrompt = `You are a task planning AI. Break down the given task into executable steps.

Available tools:
${toolList || 'No tools available.'}

Respond in JSON format:
{
  "steps": [
    {
      "id": 1,
      "action": "tool_call" | "think" | "respond",
      "tool_id": "..." (if tool_call),
      "tool_params": {...},
      "reasoning": "why this step",
      "expected_output": "what we expect"
    }
  ],
  "estimated_rounds": number,
  "requires_user_input": true/false
}

Rules:
- Start with "think" to analyze the task
- Use "tool_call" when you need external data
- End with "respond" to give the final answer
- Keep steps minimal - don't over-plan
- Each step should be independently executable`;

  const planBody = {
    model: planModel,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: `Plan this task: ${task}` },
    ],
    temperature: 0.2,
    max_tokens: 1024,
    stream: false,
  };

  try {
    const response = await handleOpenAICompatibleChat(provider, planBody, apiKey, false);
    if (response.status !== 200) {
      return jsonResponse({ steps: [{ id: 1, action: 'respond', reasoning: 'Direct response', expected_output: 'Answer' }], estimated_rounds: 1, requires_user_input: false });
    }
    const text = await response.text();
    const json = JSON.parse(text);
    const content = json['choices']?.[0]?.['message']?.['content'] || '';
    const result = JSON.parse(content);
    return jsonResponse(result);
  } catch (e) {
    return jsonResponse({ steps: [{ id: 1, action: 'respond', reasoning: 'Direct response', expected_output: 'Answer' }], estimated_rounds: 1, requires_user_input: false });
  }
}

async function handleEmbedding(request, env) {
  const body = await request.json();
  const { text, model } = body;

  const apiKey = getApiKey('openai', env);
  if (!apiKey) return jsonResponse({ error: 'Embedding service unavailable' }, 503);

  const embedModel = model || 'text-embedding-3-small';

  try {
    const response = await fetch('https://api.openai.com/v1/embeddings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      body: JSON.stringify({ model: embedModel, input: text }),
    });
    const data = await response.json();
    if (data.data?.[0]?.embedding) {
      return jsonResponse({ embedding: data.data[0].embedding, model: embedModel, tokens: data.usage?.total_tokens || 0 });
    }
    return jsonResponse({ error: 'Embedding failed' }, 500);
  } catch (e) {
    return jsonResponse({ error: 'Embedding service error' }, 500);
  }
}

async function handleTranscription(request, env) {
  const apiKey = getApiKey('openai', env);
  if (!apiKey) return jsonResponse({ error: 'Transcription service unavailable' }, 503);

  try {
    const formData = await request.formData();
    const file = formData.get('file');
    const language = formData.get('language') || 'zh';

    const whisperForm = new FormData();
    whisperForm.append('file', file);
    whisperForm.append('model', 'whisper-1');
    whisperForm.append('language', language);

    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${apiKey}` },
      body: whisperForm,
    });

    const data = await response.json();
    return jsonResponse(data);
  } catch (e) {
    return jsonResponse({ error: 'Transcription failed' }, 500);
  }
}

async function handleTTS(request, env) {
  const body = await request.json();
  const { text, voice, model } = body;

  const apiKey = getApiKey('openai', env);
  if (!apiKey) return jsonResponse({ error: 'TTS service unavailable' }, 503);

  try {
    const response = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${apiKey}` },
      body: JSON.stringify({
        model: model || 'tts-1',
        input: text,
        voice: voice || 'alloy',
      }),
    });

    return new Response(response.body, {
      status: response.status,
      headers: {
        ...corsHeaders(),
        'Content-Type': 'audio/mpeg',
        'Cache-Control': 'public, max-age=86400',
      },
    });
  } catch (e) {
    return jsonResponse({ error: 'TTS failed' }, 500);
  }
}

async function handleContentDiscover(request, env, url, origin) {
  const category = url.searchParams.get('category') || 'all';
  const count = Math.min(parseInt(url.searchParams.get('count') || '5'), 20);

  const KV = env.KV;
  const cacheKey = `discover:${category}:${new Date().toISOString().split('T')[0]}`;

  if (KV) {
    try {
      const cached = await KV.get(cacheKey, { type: 'json' });
      if (cached && cached.articles && cached.articles.length > 0) {
        return jsonResponse(cached, 200, {
          'Cache-Control': 'public, max-age=300',
          'X-Cache': 'HIT',
        }, origin);
      }
    } catch (e) {}
  }

  const categoryPrompts = {
    all: 'general interesting topics across technology, science, culture, and innovation',
    news: 'breaking news and current events worldwide',
    tech: 'latest technology breakthroughs, AI developments, and software engineering trends',
    business: 'business innovation, startups, and economic insights',
    art: 'art, culture, creative works, and design trends',
  };

  const prompt = categoryPrompts[category] || categoryPrompts.all;

  const systemPrompt = `You are a content curator for a futuristic social platform called Omnivium. Generate ${count} unique, engaging article summaries about ${prompt}. Each article should be concise, thought-provoking, and relevant to forward-thinking users. Return ONLY valid JSON in this exact format, no markdown fences:
{"articles":[{"title":"Article Title","description":"2-3 sentence engaging description","author":"Author Name","image":"","bg_color":"#1a1a2e","avatar_color":"#4a4a6a"}]}

Use varied, realistic-sounding author names. Use dark theme hex colors for bg_color (deep navy/purple tones) and lighter accent colors for avatar_color. Make titles compelling and descriptions informative.`;

  try {
    const provider = detectProvider('deepseek-chat', null);
    const apiKey = getApiKey(provider, env);

    if (!apiKey) {
      return jsonResponse({
        articles: [getDefaultDiscoverItem(category)],
        category,
        generated_at: new Date().toISOString(),
      }, 200, {}, origin);
    }

    const config = PROVIDERS[provider];
    const chatBody = {
      model: 'deepseek-chat',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: prompt },
      ],
      temperature: 0.8,
      max_tokens: 2048,
      stream: false,
    };

    let aiResponse;
    if (config.format === 'claude') {
      const claudeReq = convertToClaudeRequest(chatBody);
      const claudeRes = await fetch(`${config.baseUrl}${config.pathPrefix}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify(claudeReq),
      });
      const claudeData = await claudeRes.json();
      aiResponse = claudeData.content?.[0]?.text || '';
    } else {
      const res = await fetch(`${config.baseUrl}${config.pathPrefix}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`,
        },
        body: JSON.stringify(chatBody),
      });
      const data = await res.json();
      aiResponse = data.choices?.[0]?.message?.content || '';
    }

    let text = aiResponse.trim();
    if (text.startsWith('```')) {
      text = text.replace(/^```(?:json)?\s*/, '').replace(/\s*```$/, '');
    }

    const parsed = JSON.parse(text);
    if (!parsed.articles || !Array.isArray(parsed.articles)) {
      throw new Error('Invalid response format');
    }

    const result = {
      articles: parsed.articles.slice(0, count).map(a => ({
        title: a.title || 'Untitled',
        description: a.description || '',
        author: a.author || 'Omnivium',
        image: a.image || '',
        bg_color: a.bg_color || '#1a1a2e',
        avatar_color: a.avatar_color || '#4a4a6a',
      })),
      category,
      generated_at: new Date().toISOString(),
    };

    if (KV) {
      try {
        await KV.put(cacheKey, JSON.stringify(result), { expirationTtl: 3600 });
      } catch (e) {}
    }

    return jsonResponse(result, 200, {
      'Cache-Control': 'public, max-age=300',
      'X-Cache': 'MISS',
    }, origin);
  } catch (e) {
    return jsonResponse({
      articles: [getDefaultDiscoverItem(category)],
      category,
      generated_at: new Date().toISOString(),
    }, 200, {}, origin);
  }
}

function getDefaultDiscoverItem(category) {
  return {
    title: 'Welcome to Omnivium',
    description: 'Discover curated content powered by AI. Stay tuned for the latest updates and insights from around the world.',
    author: 'Omnivium',
    image: '',
    bg_color: '#1a1a2e',
    avatar_color: '#4a4a6a',
  };
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(origin) });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    if (path === '/health') {
      return jsonResponse({ status: 'ok', version: '3.0.0', providers: Object.keys(PROVIDERS) }, 200, {}, origin);
    }

    if (path === '/status') {
      return handleAppStatus(request, env);
    }

    if (path === '/config') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401, {}, origin);
      return handleRemoteConfig(request, env);
    }

    if (path === '/config/init' && request.method === 'GET') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401, {}, origin);
      return jsonResponse({
        supabase_url: env.SUPABASE_URL || null,
        supabase_anon_key: env.SUPABASE_ANON_KEY || null,
        backend_url: `https://${request.headers.get('host')}`,
      }, 200, {}, origin);
    }

    if (path === '/config/ssl-pins' && request.method === 'GET') {
      const pins = env.SSL_PINS ? JSON.parse(env.SSL_PINS) : {};
      return jsonResponse(pins, 200, {
        'Cache-Control': 'public, max-age=3600',
      }, origin);
    }

    if (path === '/config/encryption-key' && request.method === 'POST') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401, {}, origin);
      try {
        const body = await request.json();
        const key = body.key;
        if (!key) return jsonResponse({ error: 'Missing key' }, 400, {}, origin);
        await env.KV?.put(`enc_key:${user.id}`, key, { expirationTtl: 86400 * 30 });
        return jsonResponse({ ok: true }, 200, {}, origin);
      } catch (e) {
        return jsonResponse({ error: 'Invalid body' }, 400, {}, origin);
      }
    }

    if (path === '/auth/srp-login' && request.method === 'POST') {
      try {
        const body = await request.json();
        const { username, srp_proof, srp_id } = body;
        if (!username || !srp_proof || !srp_id) {
          return jsonResponse({ error: 'Missing fields' }, 400, {}, origin);
        }

        const storedVerifier = await env.KV?.get(`srp:${username}`);
        const storedSalt = await env.KV?.get(`srp_salt:${username}`);
        if (!storedVerifier || !storedSalt) {
          return jsonResponse({ error: 'SRP not configured' }, 400, {}, origin);
        }

        const isValid = await verifySrpProof(srp_proof, srp_id, storedVerifier, storedSalt);
        if (!isValid) {
          return jsonResponse({ error: 'SRP verification failed' }, 401, {}, origin);
        }

        const homeserver = env.MATRIX_HOMESERVER || 'https://matrix.omnivium.app';
        const matrixPassword = await env.KV?.get(`srp_pass:${username}`);
        if (!matrixPassword) {
          return jsonResponse({ error: 'No stored credentials' }, 500, {}, origin);
        }

        const loginResp = await fetch(`${homeserver}/_matrix/client/v3/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            type: 'm.login.password',
            identifier: { type: 'm.id.user', user: username },
            password: matrixPassword,
          }),
        });

        const loginData = await loginResp.json();
        if (loginData.access_token) {
          return jsonResponse({
            access_token: loginData.access_token,
            user_id: loginData.user_id,
            device_id: loginData.device_id,
            homeserver: homeserver,
          }, 200, {}, origin);
        } else {
          return jsonResponse({ error: loginData.error || 'Matrix login failed' }, 401, {}, origin);
        }
      } catch (e) {
        return jsonResponse({ error: 'SRP login failed' }, 500, {}, origin);
      }
    }

    if (path === '/auth/srp-register' && request.method === 'POST') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401, {}, origin);
      try {
        const body = await request.json();
        const { username, verifier, salt } = body;
        if (!username || !verifier || !salt) {
          return jsonResponse({ error: 'Missing fields' }, 400, {}, origin);
        }
        await env.KV?.put(`srp:${username}`, verifier, { expirationTtl: 86400 * 365 });
        await env.KV?.put(`srp_salt:${username}`, salt, { expirationTtl: 86400 * 365 });
        return jsonResponse({ ok: true }, 200, {}, origin);
      } catch (e) {
        return jsonResponse({ error: 'SRP register failed' }, 500, {}, origin);
      }
    }

    if (path === '/models') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401);
      return handleModels(env);
    }

    if (path === '/device/register' && request.method === 'POST') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401);
      return handleRegisterDevice(request, env);
    }

    const user = await authenticate(request, env);
    if (!user) return jsonResponse({ error: 'Unauthorized' }, 401);

    if (path.startsWith('/ai/')) {
      const rateCheck = await checkRateLimit(user.id, user.plan, env);
      if (!rateCheck.allowed) {
        return jsonResponse({ error: 'Rate limit exceeded', code: rateCheck.reason }, 429);
      }

      if (path === '/ai/search' && request.method === 'POST') {
        return handleSearch(request, env);
      }

      if (path === '/ai/models' && request.method === 'GET') {
        return handleModels(env);
      }

      if (path === '/ai/chat' && request.method === 'POST') {
        return handleAIChat(request, env, user);
      }

      if (path === '/ai/classify' && request.method === 'POST') {
        return handleIntentClassification(request, env);
      }

      if (path === '/ai/reflect' && request.method === 'POST') {
        return handleReflection(request, env);
      }

      if (path === '/ai/plan' && request.method === 'POST') {
        return handleMultiStepPlan(request, env);
      }

      if (path === '/ai/embed' && request.method === 'POST') {
        return handleEmbedding(request, env);
      }

      if (path === '/ai/transcribe' && request.method === 'POST') {
        return handleTranscription(request, env);
      }

      if (path === '/ai/tts' && request.method === 'POST') {
        return handleTTS(request, env);
      }

      if (path === '/ai/memory' && request.method === 'GET') {
        return handleMemoryGet(user.id, request, env);
      }

      if (path === '/ai/memory/store' && request.method === 'POST') {
        return handleMemoryStore(user.id, request, env);
      }

      const pathParts = path.split('/').filter(Boolean);
      if (pathParts.length >= 3) {
        const provider = pathParts[1];
        const apiPath = '/' + pathParts.slice(2).join('/') + url.search;
        return proxyAIRequest(provider, apiPath, request, env);
      }
    }

    if (path === '/ui/schemas') {
      return handleUISchemas(request, env);
    }

    if (path === '/content/discover') {
      const user = await authenticate(request, env);
      if (!user) return jsonResponse({ error: 'Unauthorized' }, 401, {}, origin);
      return handleContentDiscover(request, env, url, origin);
    }

    return jsonResponse({ error: 'Not found' }, 404);
  },
};
