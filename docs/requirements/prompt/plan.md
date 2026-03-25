# 简中预置提示词合成实施计划

## 背景事实

- 需求说明以 `README.md` 为准，优先遵循当前未提交版本，不要回退用户刚改过的内容
- 目标产物是 `prebuilt-prompt-zh-hans.json`
- 新来源文件是 `chat_real_user_queries_zh_mixed.json`
  - 当前包含 225 条简体中文 prompt
  - 225 条均唯一
- 旧来源文件是 `suggestions.json`
  - 只使用 `zh.chat`
  - 当前共 40 条旧 prompt
  - 分类分别为 `常识(5)`、`创作(7)`、`百科(7)`、`代码(7)`、`数学(7)`、`角色扮演(7)`
- 两个来源之间当前没有 exact duplicate prompt
  - 目标总条目数应为 `225 + 40 = 265`
- 当前 App 运行时仍主要消费 `chat_suggestions_zh.json` / `suggestions.json` 这套旧 schema
  - 本任务只生成需求侧的 `prebuilt-prompt-zh-hans.json`
  - 本任务不修改 `*`、`lib/*`、加载逻辑或评测脚本输入格式

## 目标输出

生成完整的 `prebuilt-prompt-zh-hans.json`，使用以下固定 schema：

```json
[
  {
    "category": "general",
    "display_name": "日常",
    "items": [
      {
        "rendering_name": "努力没白费，只是回报慢了",
        "prompt": "完整 prompt",
        "score": 0,
        "is_old_prompt": false
      }
    ]
  }
]
```

顶层分类必须固定为以下 6 个，且顺序不可变：

1. `general` / `日常`
2. `creation` / `创作`
3. `role_play` / `角色扮演`
4. `encyclopedia` / `百科`
5. `code` / `代码`
6. `mathematics` / `数学`

## 实施方式

采用“可重复生成”方案，不要手工一次性拼 265 条数据

1. 在 `tools/` 下新增一个生成脚本，例如 `tools/build_prebuilt_prompt_zh_hans.py`
2. 脚本默认直接生成并覆盖 `prebuilt-prompt-zh-hans.json`
3. 脚本额外支持 `--check`
   - `--check` 模式下不写文件
   - 只比较生成结果与已提交文件是否一致
   - 不一致时返回非 0 退出码
4. 脚本输出 JSON 时使用 `ensure_ascii=False`、2 空格缩进、文件末尾保留换行
5. 生成逻辑中允许使用明确的 override 表
   - `CATEGORY_OVERRIDES`
   - `RENDERING_NAME_OVERRIDES`
6. 不要为了“自动化得很漂亮”写一套复杂难维护的分类器
   - 这个任务是内容资产生产，不是机器学习项目
   - 可读、可审查、可复跑，比“聪明”更重要

## 数据合成规则

### 旧 prompt 导入规则

- 从 `suggestions.json` 的 `zh.chat` 读取旧 prompt
- 旧分类映射固定如下：
  - `常识` -> `general`
  - `创作` -> `creation`
  - `角色扮演` -> `role_play`
  - `百科` -> `encyclopedia`
  - `代码` -> `code`
  - `数学` -> `mathematics`
- 旧 prompt 的 `is_old_prompt` 固定为 `true`
- 旧 prompt 的 `score` 固定为 `0`
- 旧 prompt 的正文优先取 `prompt`
  - 如果某条没有 `prompt`，则退回 `display`

### 新 prompt 导入规则

- 从 `chat_real_user_queries_zh_mixed.json` 读取全部 225 条字符串
- 新 prompt 的 `is_old_prompt` 固定为 `false`
- 新 prompt 的 `score` 固定为 `0`
- 新 prompt 的 `prompt` 直接使用原文，最多只做首尾空白清理

### 去重规则

- 去重键使用 `prompt.strip()`
- 先处理新 prompt，再处理旧 prompt
- 如果旧 prompt 与新 prompt 完全相同，保留新 prompt，丢弃旧 prompt
- 如果同一来源内部出现重复，保留首次出现的那一条
- 不要按 `rendering_name` 去重，只按 `prompt` 去重

### 分类归属规则

对新 prompt 按“用户主要意图”分类，不按表面关键词堆砌

分类优先级固定为：

1. `role_play`
2. `creation`
3. `code`
4. `mathematics`
5. `encyclopedia`
6. `general`

按以下定义分类：

- `role_play`
  - 明确要求扮演、模拟、代入某个身份或人物口吻
  - 包括历史人物穿越到现代、考官模拟、人生导师、CEO 视角、群面模拟、毒舌角色、特定人物发言风格
- `creation`
  - 主要目标是生成或改写内容本身
  - 包括文案、故事、散文、歌词、推文、旁白、店名、slogan、logo 理念、风格化改写、润色、脚本、人物设定、AI 绘画关键词
  - 如果 prompt 既带风格人物又要求模仿口吻，优先归 `role_play`
- `code`
  - 主要目标是软件、AI 系统、程序、工具链、技术教程、实现方案
  - 包括代码实现、系统搭建、数字分身、AI 助手、工作流、Citespace 操作、开发学习路线、技术可行性方案
  - 单纯“用 AI 提升效率”的职场建议，如果核心不是搭系统或技术实现，归 `general`
- `mathematics`
  - 主要目标是数学计算、证明、公式、定量推导、明确的数学题
- `encyclopedia`
  - 主要目标是解释知识、原理、概念、现象
  - 输出偏“科普 / 概念讲解 / 客观知识说明”
  - 例如“解释沉没成本谬误”“如何向 5 岁孩子解释什么是 AI”
- `general`
  - 默认桶
  - 吸收日常生活、家庭、亲子、关系、职场、预算、职业转型、选择分析、路线规划、旅行安排、健康习惯、沟通话术、学习计划等实用型请求

### rendering_name 生成规则

- `rendering_name` 不是原 prompt 截断
- 必须是适合界面点击的短文案
- 目标长度：
  - 最好控制在 6 到 18 个简体中文字符
  - 硬上限为 30 个简体中文字符
  - 英文场景硬上限为 60 个字母
- 生成要求：
  - 保留主要意图
  - 尽量保留最有辨识度的限定词
  - 删除冗长背景、数字细节、客套句和解释性从句
  - 不使用末尾问号、句号、感叹号
  - 避免“帮我”“请你”“能不能”等口语前缀
  - 优先生成一个可以独立点击理解的短标题
- 推荐风格：
  - `努力没白费，只是回报慢了`
  - `传统企业 AI 试点方案`
  - `幼儿园分离焦虑两周方案`
  - `汪曾祺风改写`
  - `雅思口语考官模拟`
  - `AI 数字分身搭建`
- 对旧 prompt：
  - 如果原 `display` 已经足够短且适合按钮展示，可直接复用
  - 如果原 `display` 明显过长，必须压缩成新的 `rendering_name`

## 排序规则

- 顶层分类顺序固定为前述 6 个分类
- 每个分类内部顺序固定为：
  - 先放新 prompt
  - 再放旧 prompt
- 新 prompt 在分类内保持原始来源文件中的相对顺序
- 旧 prompt 在分类内保持 `suggestions.json` 中的相对顺序

## 建议实现细节

- 生成脚本内部先把所有记录统一为中间结构，再一次性组装为最终 JSON
- 中间结构建议字段：

```python
{
  "category": "general",
  "display_name": "日常",
  "rendering_name": "...",
  "prompt": "...",
  "score": 0,
  "is_old_prompt": False,
}
```

- 最后再按分类聚合成：

```python
{
  "category": "general",
  "display_name": "日常",
  "items": [...]
}
```

- 分类和标题生成先走 deterministic 规则
- 对 deterministic 规则覆盖不到或质量不够的项，再用 override 表逐条修正
- 第一版允许 override 数量较多，只要输出稳定、便于 review 即可

## 验收标准

- `prebuilt-prompt-zh-hans.json` 可被 `jq` 正常解析
- 顶层恰好有 6 个分类，且顺序正确
- 6 个分类的 `category` 值必须严格等于：
  - `general`
  - `creation`
  - `role_play`
  - `encyclopedia`
  - `code`
  - `mathematics`
- 每个分类都必须包含：
  - `category`
  - `display_name`
  - `items`
- 所有 item 都必须包含：
  - `rendering_name`
  - `prompt`
  - `score`
  - `is_old_prompt`
- 最终总条目数必须为 265
- 不允许存在空的 `rendering_name`
- 不允许存在重复 `prompt`
- 所有 `score` 必须为 `0`
- 所有新 prompt 必须是 `is_old_prompt: false`
- 所有旧 prompt 必须是 `is_old_prompt: true`
- `README.md` 不需要再改结构，除非实现结果与现有 README 再次发生冲突

## 非范围

- 不修改 `chat_suggestions_zh.json`
- 不修改 `suggestions.json`
- 不运行模型评测，不填写真实 score
- 不扩展英文、日文、韩文、俄文或繁体版本
- 不引入新的分类
