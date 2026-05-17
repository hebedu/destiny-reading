# destiny-reading

一个**分层、分支的命理 / 占星解读 skill**，给 Claude（或其他 LLM）当工具用。

三条互不混用的链路：

- **bazi**（八字）——四柱、十神、五行、大运、流年
- **astrology**（西方占星）——本命盘、行星、宫位、相位
- **synastry**（合盘）——两人比较盘 + 中点法组合盘

用户启动时先选一条，再走对应的引擎 + 提示词 + 输出模板。

## 设计原则

**确定性归代码，解读归提示词。** 两个分支共享同一套'怎么算 vs 怎么说'的分层。

```
用户输入
    ↓
方法选择 (bazi | astrology)            ← 强制单选
    ↓
统一输入包                              ← 一次成型, 禁止二次解析
    ↓                       ↓
engine/run_bazi.sh    engine/run_astrology.sh   ← Layer 1 (天文 + 数学)
    ↓                       ↓
bazi_facts.json       astro_facts.json
    ↓                       ↓
prompt/bazi.md        prompt/astrology.md       ← Layer 2 (解读规则)
+ rules/bazi/*.json   + rules/astrology/*.json
    ↓                       ↓
按 output-template.md 渲染 → 最终成品
```

## 目录结构

```
destiny-reading/
├── SKILL.md                  Claude 入口（含方法选择问询）
├── README.md                 这份说明
├── input-schema.json         统一输入包定义
├── output-template.md        最终交付栏目（两分支共用骨架）
│
├── engine/                   Layer 1（不要改）
│   ├── bazi_skill_engine.py
│   ├── astrology_engine.py
│   ├── synastry_engine.py    合盘（比较盘 + 中点法组合盘）
│   ├── seas_18.se1           Chiron 等小行星星历 (1800-2399, ~220KB)
│   ├── requirements.txt      pyswisseph
│   ├── run_bazi.sh
│   ├── run_astrology.sh
│   └── run_synastry.sh
│
├── rules/                    Layer 2 查表（按需扩展）
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
├── prompt/                   Layer 2 解读规则（你的核心创作区）
│   ├── bazi.md               八字提示词（知命先生）
│   ├── astrology.md          星座提示词（星语者・单人版）
│   ├── synastry.md           合盘提示词（星语者・合盘版）
│   ├── style_modes.md        三分支共用
│   └── refusal_rules.md      三分支共用
│
└── examples/
    ├── bazi/
    │   ├── sample_input.json
    │   ├── sample_facts.json
    │   └── sample_output.md
    ├── astrology/
    │   ├── sample_input.json
    │   ├── sample_facts.json
    │   └── sample_output.md
    └── synastry/
        ├── sample_input.json
        ├── sample_facts.json
        └── sample_output.md
```

## 安装

```bash
pip3 install -r "$HOME/Library/Mobile Documents/com~apple~CloudDocs/destiny-reading/engine/requirements.txt"
```

## 跑通验证

```bash
cd "$HOME/Library/Mobile Documents/com~apple~CloudDocs/destiny-reading"

# 八字
bash engine/run_bazi.sh examples/bazi/sample_input.json /tmp/bazi_facts.json

# 星座（单人）
bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/astro_facts.json

# 合盘：先分别算两人本命，再合
bash engine/run_synastry.sh \
  examples/astrology/sample_facts.json \
  /tmp/yang_facts.json \
  person_a person_b \
  examples/synastry/sample_facts.json
```

## 改哪里

| 想做什么 | 改哪 |
|---|---|
| 加新栏目（比如"健康"） | `output-template.md` + 对应 `prompt/{bazi|astrology}.md` |
| 改八字十神映射 | `rules/bazi/ten_gods_meaning.json` |
| 改行星语义 | `rules/astrology/planet_meaning.json` |
| 切风格（克制 vs 直断） | `prompt/style_modes.md` |
| 拒绝条件 | `prompt/refusal_rules.md` |
| 排盘 / 占星算法本身 | **不要动 `engine/`**——确定性引擎，改坏所有结果都不准 |
| 加一条新分支（紫微 / 数字命理） | 新建 `rules/<method>/` + `prompt/<method>.md` + 在 SKILL.md 第 1 步加进选择列表 |

## 重要约束

- 引擎默认**不修正真太阳时**。出生地距 120°E ≥ 7° 经度（云贵川、新疆、西藏）时主动提示用户。
- 八字引擎使用"23:00 子初换日"——命理派惯例。
- 星座引擎默认 **Tropical zodiac + Placidus 宫制**。
- 星座 engine 输出的"points"包含 **Chiron / NorthNode / SouthNode（派生）/ Lilith（Mean Black Moon）**；相位含 **Quincunx 150°**；**仍 blocked**：福点、行星 dignities、推运 / 过运。
- **两个分支不混用术语**：八字结果里不写'上升 / 行星 / 宫位'，星座结果里不写'日主 / 大运 / 十神'。

## 星历文件来源（Chiron）

`engine/seas_18.se1` 是 Chiron 等小行星的 Swiss Ephemeris 数据文件（1800-2399 年），从 [aloistr/swisseph 官方仓库](https://github.com/aloistr/swisseph/tree/master/ephe) 下载。引擎会自动找 `engine/` 目录下的 .se1 文件，不需要配置环境变量。

若需要 1800 年以前或 2400 年以后的 Chiron 位置，从同一仓库下载对应的 `seas_*.se1` 文件放进 `engine/` 即可。
