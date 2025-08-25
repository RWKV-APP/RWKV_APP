# Android 签名配置说明

本项目已配置了 Android 应用的签名，包括 debug 和 release 两种模式。

## 步骤

1. 取得 `debug.keystore` 和 `release.keystore` 文件
2. 将 `debug.keystore` 文件复制到 android/app/debug.keystore
3. 将 `release.keystore` 文件复制到 android/app/release.keystore
4. 打包
5. 上传后检查签名是否正确

## 文件说明

- `app/debug.keystore` - Debug 模式的签名文件
- `app/release.keystore` - Release 模式的签名文件
- `app/signing.properties` - 签名配置文件
- `app/proguard-rules.pro` - ProGuard 混淆规则文件

## 签名信息

### Debug 签名

- **密钥库文件**: `debug.keystore`
- **密钥库密码**: `android`
- **密钥别名**: `androiddebugkey`
- **密钥密码**: `android`

### Release 签名

- **密钥库文件**: `release.keystore`
- **密钥库密码**: `rwkvapp123`
- **密钥别名**: `rwkvapp`
- **密钥密码**: `rwkvapp123`

## 使用方法

### Debug 构建

```bash
flutter build apk --debug
```

### Release 构建

```bash
flutter build apk --release
```

## 安全注意事项

1. **不要将 keystore 文件提交到版本控制系统**

   - 这些文件已经被添加到 `.gitignore` 中
   - 请妥善保管 release.keystore 文件

2. **备份签名文件**

   - 请将 `release.keystore` 文件备份到安全的位置
   - 如果丢失，将无法更新已发布的应用

3. **密码安全**
   - 建议在生产环境中使用更强的密码
   - 可以将密码存储在环境变量中

## 修改签名配置

如果需要修改签名配置，请：

1. 更新 `signing.properties` 文件中的相应配置
2. 重新生成 keystore 文件（如果需要）
3. 更新此文档

## 验证签名

可以使用以下命令验证 APK 的签名：

```bash
jarsigner -verify -verbose -certs your-app.apk
```
