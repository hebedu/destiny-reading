# destiny-reading

一个**分层架构**的命理 / 占星解读 skill——把"算"和"说"严格分开：

- **`engine/`**：Python + 瑞士星历表，算确定性事实（四柱、行星位置、相位）
- **`prompt/`**：你的解读规则 + 人格（Markdown，可自由替换）
- **`rules/`**：语义查表（JSON，可扩展）

支持三种解读：
- **八字（bazi）**——四柱、十神、五行、大运、流年
- **西方占星（astrology）**——本命盘、行星、宫位、相位（含 Chiron / 月交点 / 莉莉丝 / Quincunx）
- **合盘（synastry）**——**双盘合参**：两人比较盘 + 中点法组合盘（星盘）+ 双方八字 + 八字合婚 + 双盘交叉印证

可以喂给 **Claude Code / Codex / Cursor / Cline / Aider** 等任何能读 markdown + 调 shell 的 AI 助手。也能纯命令行用。

---

## 30 秒看懂

```
用户输入 (姓名/性别/生辰/出生地)
      ↓
engine/run_*.sh  ←  瑞士星历精算 (节气、行星位置、相位...)
      ↓
facts.json (确定性事实)
      ↓
prompt/*.md + rules/*.json  ←  你的解读人格 + 语义查表
      ↓
中文解读成品
```

**核心约束**：LLM 不参与计算——任何"算得对"的事都由 engine 完成。LLM 只负责"说得好"。

---

## 5 分钟跑通

```bash
# 1. 拉代码
git clone https://github.com/<your-username>/destiny-reading.git
cd destiny-reading

# 2. 一键安装（装依赖 + 检查星历 + 注册到 Claude Code）
bash scripts/install.sh

# 3. 跑一个样例
bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/out.json
cat /tmp/out.json | head -40
```

如果你用 Claude Code，重启后直接说"帮我看下星盘 / 算下八字 / 看合盘"，它会自动识别这个 skill。

---

## 三种使用路径，按你的需求选

| 路径 | 你是谁 | 怎么用 |
|---|---|---|
| **A · Claude Code skill** | Claude Code 用户 | 跑 `install.sh` → 自动软链到 `~/.claude/skills/destiny-reading/` → 重启 CC → 直接对话调用 |
| **B · 喂给其他 AI 工具** | Codex / Cursor / Cline / Aider 用户 | 把整个目录当工程打开，让 AI 读 `SKILL.md` + 对应 `prompt/*.md`，自己跑 engine |
| **C · 命令行工具** | 不依赖 AI 助手 | 直接跑 `engine/run_*.sh`，拿 JSON 自己处理 / 喂给别的服务 |

详细安装见 [INSTALL.md](INSTALL.md)。

---

## 目录结构

```
destiny-reading/
├── SKILL.md                  入口 · 启动问询 / 三分支流程 / 输出合同
├── README.md                 本文件
├── INSTALL.md                各种 AI 工具下的安装方式
├── CUSTOMIZE.md              怎么把 prompt 换成你自己的
├── AGENTS.md                 给任何 AI 助手的引导（让它自动帮用户 setup）
├── CLAUDE.md                 Claude Code 专用补充
├── LICENSE                   MIT
│
├── scripts/
│   └── install.sh            一键安装脚本
│
├── engine/                   Layer 1 · 确定性计算（不要改）
│   ├── bazi_skill_engine.py
│   ├── astrology_engine.py
│   ├── synastry_engine.py
│   ├── seas_18.se1           Chiron 等小行星星历 (~220KB)
│   ├── requirements.txt
│   ├── run_bazi.sh
│   ├── run_astrology.sh
│   └── run_synastry.sh
│
├── rules/                    Layer 2 · 语义查表（可扩展）
│   ├── bazi/
│   │   ├── ten_gods_meaning.json
│   │   ├── structure_personality.json
│   │   └── element_advice.json
│   └── astrology/
│       ├── planet_meaning.json
│       ├── sign_meaning.json
│       ├── house_meaning.json
│       └── aspect_meaning.json
│
├── prompt/                   Layer 2 · 解读人格（你的创作区）
│   ├── bazi.md
│   ├── astrology.md
│   ├── synastry.md
│   ├── style_modes.md
│   └── refusal_rules.md
│
├── output-template.md        单人解读的输出栏目模板
├── input-schema.json         统一输入字段定义
│
└── examples/                 样例输入 + facts（不含解读输出）
    ├── bazi/
    ├── astrology/
    └── synastry/
```

---

## 改哪里、不改哪里

| 想做什么 | 改哪 | 注意 |
|---|---|---|
| 把解读人格换成自己的 | `prompt/*.md` | 保留顶部"A. 输入预备"那一段 |
| 改十神 / 行星语义映射 | `rules/<branch>/*.json` | 兼容现有 schema |
| 切风格 (克制 vs 直断) | `prompt/style_modes.md` | — |
| 调整拒绝条件 | `prompt/refusal_rules.md` | — |
| 改输出栏目 | `output-template.md` / `prompt/<branch>.md` | — |
| 加新方法（如紫微）| 新建 `rules/<method>/` + `prompt/<method>.md`，在 `SKILL.md` 第 1 步加选项 | engine 也要写对应的 |
| **排盘算法本身** | ❌ **不要改 `engine/`** | 改坏所有结果都不准 |

详细见 [CUSTOMIZE.md](CUSTOMIZE.md)。

---

## 重要约束

- 引擎默认**不修正真太阳时**。出生地距 120°E ≥ 7° 经度（云贵川、新疆、西藏等）时主动提示用户。
- 八字引擎使用"23:00 子初换日"——命理派惯例。
- 星座引擎默认 **Tropical zodiac + Placidus 宫制**。
- **术语隔离 vs 合盘例外**：
  - **八字** 分支禁出现"上升 / 行星 / 宫位"
  - **星座** 分支禁出现"日主 / 大运 / 十神"
  - **合盘** 分支是双盘合参，**唯一允许同时使用两套术语**——这是它独有的特性
- 不预言"必定 / 必然 / 注定"，用"倾向 / 容易 / 建议关注"。

---

## 设计哲学

这个 skill 是**分层架构在 LLM 工具上的实践**：

**Layer 1（engine）确定性归代码**——所有"算得对 / 算不对"的事不能让模型做。
**Layer 2（rules + prompt）解读归提示词**——所有"说得好 / 说得准"的事不能让代码做。

这样的好处：
- 引擎计算 100% 可复现，同一输入永远得到同一 facts
- 提示词层可以独立迭代而不影响事实正确性
- 模型不会"幻觉"出不存在的相位或位置
- 解读风格可以按需切换、按用户偏好定制

是想做类似 AI 工具的人可以照搬这套结构。

---

## 星历文件来源（Chiron）

`engine/seas_18.se1` 是 Chiron 等小行星的 Swiss Ephemeris 数据文件（1800-2399 年），从 [aloistr/swisseph](https://github.com/aloistr/swisseph/tree/master/ephe) 官方仓库下载。`install.sh` 会自动下载，你不用手动操作。

若需要 1800 年以前或 2400 年以后的 Chiron 位置，从同一仓库下载对应的 `seas_*.se1` 文件放进 `engine/` 即可。

---

## License

MIT. 见 [LICENSE](LICENSE)。

代码、引擎、JSON 规则都是 MIT。你可以自由使用、修改、商用。
`prompt/*.md` 里的解读人格是项目作者的原创创作，也按 MIT 发布——你可以参考、可以照搬，但建议替换成你自己的风格（CUSTOMIZE.md 说了怎么做）。
