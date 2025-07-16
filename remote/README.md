# RWKV Model API 文档

## 配置接口

### 获取配置信息

根据客户端版本获取相应的配置信息。

**请求 URL**

```
GET /get-demo-config
```

**请求头**
| 参数名 | 类型 | 必填 | 描述 |
| --- | --- | --- | --- |
| x-api-key | string | 是 | API 密钥，用于验证请求合法性 |
| application-build-number | number | 否 | 客户端构建号，用于决定返回哪个配置文件 |

**配置文件选择规则**

- 当 `application-build-number` > 440 时，返回 new-config.json
- 当 `application-build-number` ≤ 440 或未提供时，返回 demo-config.json
- 当解析失败时，默认返回 demo-config.json

**成功响应**

```json
{
  "success": true,
  "message": "Get new config success.", // 或 "Get demo config success."
  "data": {
    "chat": {
      "latest_build": 326,
      "note_zh": ["..."],
      "note_en": ["..."],
      "android_url": "https://www.pgyer.com/rwkvchat",
      "ios_url": "https://testflight.apple.com/join/DaMqCNKh",
      "model_config": [
        // 模型配置列表
      ]
    }
  }
}
```

**错误响应**

```json
{
  "success": false,
  "message": "错误信息",
  "data": null
}
```

### 更新 config 文件

配置文件更新流程说明。

**步骤 1: 准备配置文件**

准备需要更新的配置文件，文件名必须为以下两种之一：

- `demo-config.json` - 用于构建号 ≤ 440 或未提供构建号的客户端
- `new-config.json` - 用于构建号 > 440 的客户端

**步骤 2: 上传配置文件**

将配置文件上传至服务器指定目录：

```
/var/www/api-model/json/
```

可以使用 SFTP、SCP 等工具进行上传：

```bash
scp your-config.json user@server:/var/www/api-model/json/demo-config.json
```

或

```bash
scp your-config.json user@server:/var/www/api-model/json/new-config.json
```

**步骤 3: 重新加载应用**

上传完成后，需要重新加载应用以应用新的配置文件：

```bash
pm2 reload 6
```

**注意事项**

- 确保配置文件格式正确，符合 JSON 规范
- 上传前建议对配置文件进行备份
- 配置文件更新后，服务会立即根据客户端构建号返回相应的配置

## 健康检查接口

### 检查服务状态

检查服务器是否正常运行。

**请求 URL**

```
GET /health
```

**成功响应**

```json
{
  "success": true,
  "message": "Server is running"
}
```

## 限流说明

为保障服务稳定性，API 接口设有请求频率限制：

- `/upload` 接口：每个 IP 每 15 分钟最多 100 次请求
- `/get-demo-config` 接口：每个 IP 每分钟最多 1000 次请求

超出限制将返回相应的错误信息。
