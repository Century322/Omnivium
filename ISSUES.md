# Omnivium 问题清单

> 版本：2.0 | 日期：2026-05-25 | 状态：待确认

---

## 问题 1：安全区颜色闪烁

### 现象
启动App时，顶部状态栏和底部安全区的颜色与页面背景色不一致，过一会才变正常。深色主题和浅色主题都有这个问题。

### 精确原因

**深色主题：**
- 原生Android `?android:colorBackground` 解析为 `#121212`（Material默认暗色）
- Flutter期望 `AppColors.background` = `#1C1C1E`
- 色差：`#121212` vs `#1C1C1E`

**浅色主题：**
- 原生Android `?android:colorBackground` 解析为 `#FFFFFF`（纯白）
- Flutter期望 `AppColors.lightBackground` = `#F5F5F7`
- 色差：`#FFFFFF` vs `#F5F5F7`

**4个层面的问题：**

1. **`drawable-v21/launch_background.xml`** 用了 `?android:colorBackground` 而非具体颜色
2. **`NormalTheme` 的 `windowBackground`** 也用了 `?android:colorBackground`
3. **加载画面没有 `AnnotatedRegion`**，系统UI颜色不受Flutter控制
4. **只有一套 `values/colors.xml`**（`#1C1C1E`），浅色模式需要 `#F5F5F7`

### 涉及文件
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values/colors.xml`（需拆分深浅两版）
- `lib/main.dart`（加载画面加AnnotatedRegion）

---

## 问题 2：硬编码未国际化文本（全项目扫描结果）

### 需要国际化的文本（共21处）

**Semantics无障碍标签（4处）：**

| 文件 | 行号 | 硬编码文本 |
|------|------|-----------|
| voice_message.dart | 286 | `'Pause voice message'` / `'Play voice message'` |
| friend_chat_panel.dart | 1677 | `'Send message'` / `'Voice input'` |
| animated_toggle.dart | 69-70 | `'Enabled'` / `'Disabled'` |
| notification_view.dart | 133 | `'unread'` |

**技术标识符显示名称（4处）：**

| 文件 | 行号 | 硬编码文本 |
|------|------|-----------|
| settings_view.dart | 870 | `'Default'`（图片模型选项） |
| settings_view.dart | 46 | `'Default'`（_imageModel默认值） |
| settings_view.dart | 77 | `'Default'`（SharedPreferences默认值） |
| settings_view.dart | 334 | `_imageModel`直接显示给用户 |

**日期/时间格式（8处）：**

| 文件 | 行号 | 硬编码格式 |
|------|------|-----------|
| format_utils.dart | 11 | `'${dt.month}/${dt.day}'` |
| message_list_view.dart | 580 | `'${dt.month}/${dt.day}'` |
| contacts_view.dart | 493 | `'${dt.month}/${dt.day}'` |
| file_manager_view.dart | 338 | `'${dt.month}/${dt.day} HH:mm'` |
| productivity_view.dart | 448 | `'yyyy/MM/dd HH:mm'` |
| my_id_view.dart | 789 | `'yyyy-MM-dd'` |
| ai_operation_log_view.dart | 414 | `'HH:mm:ss'` |
| agent_replay_view.dart | 219 | `'HH:mm:ss'` |

**月份缩写（1处，12个值）：**

| 文件 | 行号 | 硬编码文本 |
|------|------|-----------|
| productivity_view.dart | 431-442 | `'Jan'`~`'Dec'` |

**存储单位（3处）：**

| 文件 | 行号 | 硬编码文本 |
|------|------|-----------|
| file_manager_view.dart | 340-342 | `'B'`/`'KB'`/`'MB'` |
| storage_view.dart | 77-79 | `'0 MB'`/`'KB'`/`'MB'` |
| storage_view.dart | 150 | `'0 MB'` |

**提示文本（1处）：**

| 文件 | 行号 | 硬编码文本 |
|------|------|-----------|
| add_friend_view.dart | 265 | `'@user:server.com'` |

### 不需要国际化的
- 品牌名：Omnivium、Matrix、DALL-E 3、OpenAI Whisper、Google Speech-to-Text
- 产品名：Kyrin、Alloy、Echo、Nova、Shimmer（OpenAI语音产品名）
- 语言原生名：中文、English、日本語、한국어（语言选择器标准做法）
- 强调色名称：**已国际化**，`t('accent_${preset.key}')` 已在ARB中定义

---

## 问题 3：语音输入区重构

### 当前布局
```
左侧：[+选项] [model选择]          右侧：[隐身] [🎤STT] [多功能按钮]
```

多功能按钮3种状态：
- 空输入 → VoiceBarsIcon（进入AI语音页）← 要移除
- 有文字 → ↑发送
- 生成中 → ■停止

### 改动方案
1. 移除 `onOpenVoice` 回调和 VoiceBarsIcon 按钮
2. 有文字时：麦克风STT按钮位置变为发送按钮
3. 空输入时：最右侧显示麦克风STT
4. 动画优化：按钮切换更丝滑

### 涉及文件
- `lib/presentation/widgets/chat_input_area.dart`
- `lib/presentation/views/home_view.dart`

---

## 问题 4：好友/联系人页面（暂缓）

### 已确认的问题
1. 左上角视图切换按钮无效
2. 浅色模式输入框对比度极低
3. AddFriendView两个输入框风格不统一
4. 搜索栏与AppBar视觉断层
5. labelText缺少显式labelStyle

---

## 问题 5：模型未推送

### 精确排查结果

**已确认的事实：**
- 用户使用真机测试
- Docker服务器在用户电脑上，端口8787（docker-compose.yml确认）
- 登录是统一登录，Matrix登录后所有服务自动登录
- `api_proxy_service.dart:31` 硬编码忽略 `http://10.0.2.2:8787`（模拟器地址），真机无法连接本地Docker
- `app_config.dart:47` 开发环境默认API地址也是 `http://10.0.2.2:8787`

**确切问题：真机无法连接本地Docker服务器**
- `10.0.2.2` 是Android模拟器访问宿主机的专用地址，真机无法解析
- 真机需要用电脑的局域网IP（如 `http://192.168.x.x:8787`）
- 代码中 `10.0.2.2:8787` 被硬编码忽略，回退到Cloudflare生产URL
- 如果Cloudflare生产URL也没有配置API Key，模型列表为空

**Docker API Key配置：**
- `docker-compose.yml` 中API Key通过环境变量注入：`${OPENAI_API_KEY:-}`（默认为空）
- 需要检查是否有 `.env` 文件或启动时是否传入了API Key

### 结论
**确切问题：真机无法连接本地Docker，因为代码只识别模拟器地址。** 需要支持真机通过局域网IP连接本地服务器。
