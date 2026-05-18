# Firebase 推送通知配置指南

## 前置条件
- 创建 Firebase 项目: https://console.firebase.google.com/
- 添加 Android 应用 (包名: com.omnivium.mobile)
- 添加 iOS 应用 (Bundle ID: com.omnivium.mobile)

## Android 配置
1. 从 Firebase Console 下载 `google-services.json`
2. 放置到 `mobile/android/app/google-services.json`
3. 在 `mobile/android/build.gradle.kts` 添加:
   ```kotlin
   id("com.google.gms.google-services")
   ```
4. 在 `mobile/android/app/build.gradle.kts` 添加:
   ```kotlin
   id("com.google.gms.google-services")
   ```

## iOS 配置
1. 从 Firebase Console 下载 `GoogleService-Info.plist`
2. 放置到 `mobile/ios/Runner/GoogleService-Info.plist`
3. 在 Xcode 中添加 APNs 证书

## Flutter 依赖
在 mobile/pubspec.yaml 中添加:
```yaml
firebase_core: ^3.12.1
firebase_messaging: ^15.2.4
flutter_local_notifications: ^18.0.1
```

## 注意事项
- google-services.json 和 GoogleService-Info.plist 不应提交到版本控制
- 已在 mobile/.gitignore 中排除这些文件
