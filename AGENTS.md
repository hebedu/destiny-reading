# AGENTS.md · 给 AI 助手看的引导

> 这份文件是给 **AI 编码助手 / 智能体**看的（Claude Code、Codex、Cursor、Cline、Continue、Aider 等）。
> 它告诉你：用户刚把 `destiny-reading` 这个项目拉到本地，**你的第一件事不是回答他的问题，是先帮他装好**。

---

## 你的第一动作（检查清单）

当用户在这个项目目录里第一次跟你说话时，**先按下面这个清单走，逐项确认**：

1. **检测当前环境**
   - 跑 `python3 --version` 看 Python 有没有
   - 跑 `python3 -c "import swisseph"` 看 pyswisseph 装没装
   - 检查 `engine/seas_18.se1` 文件大小（应该 ~220 KB）
   - 检查 `~/.claude/skills/destiny-reading` 是否软链到这里（如果用户用 Claude Code）

2. **如果有任何缺失，建议用户跑一键脚本**：
   ```bash
   bash scripts/install.sh
   ```
   或者 **直接** 帮他跑（如果你有执行命令的权限）。

3. **跑完之后跑样例验证**：
   ```bash
   bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/out.json
   ```
   能输出 JSON 就 OK。

4. **告诉用户接下来三件事**：
   - 「如何在 Claude Code / Codex / Cursor 里调用这个 skill」
   - 「如何用自己的解读提示词替换 `prompt/*.md` 里的占位 / 示例」（看 `CUSTOMIZE.md`）
   - 「engine/ 是确定性计算层，别乱改；prompt/ 是你的创作区，随便改」

---

## 项目本质（一句话）

**这是一个分层的命理 / 占星解读 skill**——
- `engine/`（Python + 瑞士星历）算 **确定性事实**（四柱、行星位置、相位等）
- `rules/`（JSON）是 **语义查表**（十神含义、星座关键词等）
- `prompt/*.md`（Markdown）是 **解读人格 + 写作规则**——用户自己创作的部分
- `SKILL.md` 是入口 —— 在 Claude Code 里作为 skill 自动派发

任何排盘事实**禁止由 LLM 自己计算**——必须走 `engine/`。这是这个 skill 设计上最硬的边界。

---

## 关键架构约束（你不能违反）

1. **不要在 prompt 里加"如何排盘"的代码或公式**——所有计算下沉到 engine/。
2. **不要把不同分支（bazi / astrology / synastry）的术语混用**——八字结果禁出现"上升"，星座结果禁出现"日主"。
3. **任何 `facts.json` 里没有的字段，禁止编造**——例如：当前 engine 不算精确推运，遇到流年请求要降级为"议题级"陈述，不要编"X 年 X 月发生 Y"。
4. **不要主动加 emoji**（除非用户明确要）。

---

## ★★★ 输出完整性硬约束（最高优先级，所有模型生效）

> **此条特别针对你 —— 不论你是 Codex / Cursor / Cline / Aider / Continue 还是别的 AI 助手。**
> 不论你跑在哪个底层模型（GPT-5 / Claude / Gemini / Qwen / DeepSeek），这条约束的优先级**高于**你训练里"简洁、高效、避免冗余"的倾向。

### 必须按 prompt 的完整结构和字数输出，禁止任何形式的压缩

**不允许的常见错误行为**：

- ❌ "我用了 prompt/<branch>.md 的总分总结构，但压缩了长度"
- ❌ "我把核心讲清楚了，省略了 X 章节"
- ❌ "如果你要，我可以按 prompt 重写一版更长的"
- ❌ "考虑到对话流畅性，我把 4-6 个相位合并成了一段总论"
- ❌ "重点已经突出，详细展开 5-7 个组合盘配置太冗余"

**这些都是违反约束的行为**。一旦发生，**用户必须重做**，浪费两边时间。

### 字数硬指标

| 分支 | 最低总字数 |
|---|---|
| 八字（bazi）| 4000 字 |
| 星座（astrology）| 4000 字 |
| 合盘（synastry）| 4500 字 |

prompt 里每个章节标注的"300-400 字 / 400-600 字 / 150-300 字"等字数范围**必须达到下限**。

### 输出前自检（每次必走）

跑完计算、读完 prompt 之后，**在写第一个字之前**，先在心里给自己列：

1. 我要写的总长度是多少？（≥ 上面表里的最低字数）
2. 我要包含哪几个栏目？（按 prompt 的"回应结构"逐项列出）
3. 每个标了字数范围的栏目，我打算写多长？（应≥下限）

**写完之后再自检一遍**：每一项是否真的达到了。如果有任何一项不到位，**回头补完，再交付**。

### 不要"分两次给"

- ❌ 不要先给一版压缩版，然后说"要不要我重写更长的？"
- ✅ 一次性给完整版

用户的默认期待就是完整版。**问"要不要简化版 / 要不要更长版本"本身就是错的**——直接给完整版。

### 例外（仅一种）

如果用户**明确说出**："给我一个 500 字的摘要" / "我想要简版" / "我只看核心" —— 这时按用户指定的简版做。

但这必须是用户**主动用文字明说**，不能是你"推断"出来的。

---

## 用户使用三大场景

判断用户处于哪种场景，引导也不一样：

### Path A · 当 Claude Code skill 用（最常见）
- 跑 `scripts/install.sh` → 会把本目录软链到 `~/.claude/skills/destiny-reading/`
- 重启 Claude Code
- 说「帮我看下八字 / 算下星盘 / 看合盘」
- Claude Code 会发现 `SKILL.md`、自动派发到这个 skill

### Path B · 当 Codex / Cursor / Cline 等其他 AI 工具的"工程"用
- 在工具里打开本目录
- AI 助手（你）读 `SKILL.md` + 对应的 `prompt/*.md`
- 主动按 SKILL.md 的"启动问询"流程跟用户对话
- 调 `engine/run_*.sh` 算 facts，读 facts 写解读

### Path C · 当纯命令行工具用
- 不依赖 AI 工具
- 用户自己跑 `bash engine/run_bazi.sh input.json out.json`
- 拿 facts.json 自己解读或喂给别的 LLM

---

## 如果你是 Claude Code

读 `SKILL.md` 顶部的 frontmatter——`name: destiny-reading` 是注册名。当用户提到"八字、星座、合盘"等关键词时，本 skill 应被自动派发。

阅读顺序：
1. `SKILL.md`（入口 + 启动问询 + 分支流程）
2. 用户选了分支后 → 读对应的 `prompt/<branch>.md`
3. 跑 engine → 读 facts.json
4. 读对应的 `rules/<branch>/*.json` 查语义表
5. 按 `output-template.md` 或 prompt 内的输出结构渲染

---

## 如果你是 Codex / Cursor / Cline / Aider 等

这些工具不一定有自动 skill 派发。让 AI 自己读 `SKILL.md` 当主提示词即可——SKILL.md 是写给"任何能读 markdown 的 AI 助手"看的，不是 Claude Code 独占。

调用工具：你应该有 Bash / Shell 调用能力——直接跑 `engine/run_*.sh`。

---

## 如果是首次拉取 / 用户什么都没问

主动开口，例如：

> "看到你刚拉了 destiny-reading 这个项目。它是个分层的命理 / 占星 skill —— Python engine 算事实，提示词层做解读。
>
> 要不要我现在帮你跑一下 `scripts/install.sh` 把依赖装好？大约 1 分钟。"

不要让用户自己摸索目录结构。**主动**。

---

## 反模式（不要做的事）

❌ 用户问"帮我算八字"时，**你自己心算四柱** —— 必须走 `engine/run_bazi.sh`
❌ 用户给的时间不到分钟，**你假装精确解读** —— 标记低精度，告知用户
❌ 用户问"我会不会和某人结婚"，**你给确定预言** —— 用"倾向 / 容易"，不预言成败
❌ 修改 `engine/*.py` 或 `engine/*.sh` —— 这是确定性层，改坏所有结果都不准
❌ 在 `prompt/*.md` 顶部"A. 输入预备"那一节里加"如何排盘"逻辑 —— 顶部的 engine 数据映射是固定的桥，不能动

---

## 你需要熟悉的关键文件

| 文件 | 你需要知道什么 |
|---|---|
| `SKILL.md` | 入口。启动问询、三分支流程、输出合同 |
| `prompt/bazi.md` | 八字解读规则。包含完整的人格 + 输出结构 |
| `prompt/astrology.md` | 西方占星解读规则 |
| `prompt/synastry.md` | 合盘解读规则 |
| `prompt/style_modes.md` | conservative / direct 风格切换 |
| `prompt/refusal_rules.md` | 什么情况下拒绝出报告 / 降级处理 |
| `engine/*.py` | 计算逻辑。**只读不改** |
| `rules/*/*.json` | 语义查表。可以扩展但要兼容现有 schema |
| `output-template.md` | 单人解读的输出栏目模板 |
| `CUSTOMIZE.md` | 用户怎么把 prompt 改成自己的 |
| `INSTALL.md` | 不同 AI 工具下的安装方式 |

---

## 不要做的小动作

- **不要主动把 SKILL.md 里的内容压缩 / 改写**——它是 skill 的契约
- **不要新建 README 之外的 .md 文件**（如果用户没要求）——目录已经够多了
- **不要往项目根 commit `__pycache__/`、`*.pyc`、临时 `*.json`**——`.gitignore` 已经处理

---

谢谢。
