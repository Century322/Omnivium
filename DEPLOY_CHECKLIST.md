# Omnivium 上架部署指南

## 一、手动配置（上架前必须完成）

### 1. 生成签名密钥库

```powershell
cd android\keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. 填写 key.properties 密码

文件：`android/key.properties`

```
storePassword=你的密钥库密码
keyPassword=你的密钥密码
storeFile=keystore/upload-keystore.jks
keyAlias=upload
```

### 3. 下载 Firebase 配置文件

1. 前往 https://console.firebase.google.com/
2. 创建项目，添加 Android 应用（包名：`com.omnivium.mobile`）
3. 下载 `google-services.json` 放入 `android/app/`
4. （iOS）下载 `GoogleService-Info.plist` 放入 `ios/Runner/`

详细步骤参考 Firebase 官方文档

### 4. 放入应用图标源文件

- `assets/icon/app_icon.png` — 1024×1024 主图标（含背景）
- `assets/icon/app_icon_foreground.png` — 1024×1024 前景（透明背景）

设计参考 [ICON_DESIGN_GUIDE.md](ICON_DESIGN_GUIDE.md)

然后运行：
```powershell
dart run flutter_launcher_icons
```

### 5. 注册开发者账号

- Google Play Console：https://play.google.com/console/ （一次性 $25）
- Apple Developer（如需 iOS）：https://developer.apple.com/ （$99/年）

### 6. 部署隐私政策和服务条款

- 隐私政策：https://omnivium.app/privacy
- 服务条款：https://omnivium.app/terms

### 7. 配置自定义 API 域名

当前后端使用 `workers.dev` 开发域名，生产环境需替换为 `api.omnivium.app`：

1. 在 Cloudflare 添加 `api.omnivium.app` DNS 记录
2. 在 Cloudflare Workers 中绑定自定义域名
3. 在 App 设置中更新代理 URL

### 8. 预置证书固定哈希

文件：`lib/core/network_security_service.dart`

```bash
# 获取 api.omnivium.app 的证书哈希
openssl s_client -connect api.omnivium.app:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
```

---

## 二、安全加固（P0）

### 1. SSL Pinning 证书锁定
- **问题**：当前任何代理工具（Charles/mitmproxy）都可以抓取所有网络请求
- **方案**：在 HTTP 客户端中锁定服务器证书指纹
- **步骤**：
  ```bash
  # 1. 获取证书指纹
  openssl s_client -connect your-api-domain.com:443 | openssl x509 -fingerprint -sha256
  # 2. 在代码中配置证书指纹
  # 3. 测试：用 Charles 代理应无法连接
  ```

### 2. API Key 迁移到服务端
- **问题**：直连模式下 API Key 可被提取
- **方案**：部署 Cloudflare Worker 代理
- **步骤**：
  ```bash
  # 1. 安装 wrangler
  npm install -g wrangler
  # 2. 登录 Cloudflare
  wrangler login
  # 3. 设置密钥
  cd deploy/api-proxy
  wrangler secret put OPENAI_API_KEY
  wrangler secret put ANTHROPIC_API_KEY
  wrangler secret put GEMINI_API_KEY
  wrangler secret put PROXY_TOKEN
  # 4. 部署
  wrangler deploy
  # 5. 在 App 设置中配置代理 URL 和 Token
  ```

### 3. Root/越狱检测
- **问题**：root 设备可以读取应用沙箱数据
- **方案**：检测 root/越狱后警告用户或限制功能

### 4. 代码签名 & 混淆构建
- **步骤**：
  ```powershell
  # 用构建脚本（已创建）
  .\build_release.ps1
  ```

---

## 三、应用商店提交材料

### Google Play Store
| 材料 | 状态 | 说明 |
|------|------|------|
| AAB 文件 | ⚠️ 需构建 | `flutter build appbundle --obfuscate` |
| 应用图标 512x512 | ❌ 需设计 | |
| 宣传图 1024x500 | ❌ 需设计 | |
| 隐私政策 URL | ❌ 需部署 | |
| 内容分级问卷 | ❌ 需填写 | |
| 目标受众 | ❌ 需选择 | |

### Apple App Store（如果做 iOS）
| 材料 | 状态 | 说明 |
|------|------|------|
| IPA 文件 | ❌ 需 Mac 构建 | |
| App Store Connect 配置 | ❌ 需开发者账号 | $99/年 |
| 截图 6.7" + 6.5" | ❌ 需制作 | |
| 隐私政策 URL | ❌ 需部署 | |
| App 审核 | ❌ | E2EE 需要说明 |

---

## 四、后端部署

### 已有服务
| 服务 | 状态 | 部署方式 |
|------|------|---------|
| Matrix Synapse | ✅ 已有 | Docker Compose |
| API 代理 | ✅ 已部署 | Cloudflare Workers |
| Supabase Auth | ✅ 已集成 | Supabase Cloud |
| 数据同步 | ✅ 已集成 | Supabase PostgreSQL（4表 + RLS） |
| 应用层加密 | ✅ 已实现 | AES-256-GCM |
| 两步验证 | ✅ 已实现 | TOTP |
| 推送加密 | ✅ 已实现 | EncryptionService |

### 需要新增
| 服务 | 优先级 | 技术选择 | 成本 |
|------|--------|---------|------|
| 推送服务 | P1 | Firebase FCM | 免费 |
| 文件存储 | P2 | Cloudflare R2 | ~$0.015/GB |
| 域名 + SSL | P0 | Cloudflare | ~$10/年 |

---

## 五、安全加固检查清单

- [x] SSL Pinning 框架就绪（待配置真实证书 hash）
- [x] API Key 已迁移到服务端代理
- [x] Root/越狱检测已启用
- [x] 代码混淆构建已验证（CI 已配置 --obfuscate）
- [x] ProGuard 规则已测试
- [x] 敏感字符串已加密（API Key 不硬编码）
- [x] 网络请求全部 HTTPS
- [x] 本地敏感数据使用 flutter_secure_storage
- [x] 日志中无敏感信息泄露
- [x] 应用层加密（AES-256-GCM，密钥不再同步服务器）
- [x] HMAC 请求签名 + 时间戳防重放
- [x] Matrix Token 服务端验证
- [x] 两步验证（TOTP）
- [x] 推送载荷加密
- [x] 多端点故障转移
- [x] 应用锁（PIN 码 + 生物识别）
- [x] 加密文件存储（AES-256）
- [x] SRP 安全远程密码
- [x] 截屏/录屏保护框架
- [x] Firebase Analytics 集成
- [ ] Supabase 数据库表已创建（执行 deploy/supabase-schema.sql）
- [ ] SSL Pinning 真实证书 hash 已配置（通过 SSL_PINS 环境变量）
- [ ] 截屏/录屏保护完善（可选，金融级）

---

## 六、推荐部署顺序

1. **注册域名** → omnivium.app
2. **部署 Cloudflare Worker** → API 代理
3. **配置 DNS + SSL** → Cloudflare 一键
4. **部署隐私政策页面** → Cloudflare Pages
5. **设计应用图标** → flutter_launcher_icons
6. **构建混淆 APK** → build_release.ps1
7. **内部测试** → 10+ 人测试
8. **提交 Google Play** → 审核约 3-7 天
9. **（可选）iOS 版本** → 需 Mac + 开发者账号
