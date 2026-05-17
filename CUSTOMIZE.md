# CUSTOMIZE.md · 把这个 skill 改成你的

`destiny-reading` 的设计就是**让你方便地把解读人格换成自己的**。下面告诉你改哪、不改哪。

---

## 分层概念（先记住这个）

```
engine/         ← 不要改（计算正确性的保障）
rules/          ← 可以扩展（语义查表）
prompt/         ← 你的核心创作区（解读人格 + 写作规则）
SKILL.md        ← 顶部 frontmatter 别动；中间流程可以微调
```

---

## 改 prompt（最常见的事）

`prompt/` 目录里三份解读规则文件：

| 文件 | 控制什么 |
|---|---|
| `prompt/bazi.md` | 八字解读人格 + 输出结构 |
| `prompt/astrology.md` | 西方占星解读人格 + 输出结构 |
| `prompt/synastry.md` | 合盘解读人格 + 输出结构 |
| `prompt/style_modes.md` | 风格切换（克制 vs 直断）|
| `prompt/refusal_rules.md` | 输入不全 / 越界请求的处理 |

### 三段绝对要保留的内容（不动）

每份 `prompt/*.md` 顶部都有这三段——**改它们会让 engine 接不上**，请保留：

1. **顶部 frontmatter / 文件头**
2. **"A. 输入预备 · engine 数据映射表"**——告诉 LLM 哪个字段来自哪个 facts 字段
3. **"跨分支约束"**（文件底部）——禁止术语混用

### 中间任意改

人格、说话方式、分析框架、回应结构、原则、开场白——**全部可以替换成你自己的**。

### 改 prompt 的具体流程

1. 在 `prompt/bazi.md` 找到"角色设定"那一节
2. 删掉里面的具体内容
3. 贴你自己的人格描述（取个名字、定语气、讲方法论）
4. 调整"分析框架"——你信奉哪种命理流派，就写哪种的步骤
5. 调整"回应结构"——你想要什么样的输出栏目
6. 保留底部"跨分支约束"
7. **测试**：在 Claude Code 里说"帮我看八字"，看输出像不像你想要的

### 三个分支的注意

- **八字 prompt 里不要出现星座术语**（上升 / 行星 / 金星 / 宫位）
- **星座 prompt 里不要出现八字术语**（日主 / 大运 / 十神）
- **合盘 prompt 不要混用**——它是基于星座的，禁用八字术语

---

## 扩展 rules（加新的查表）

`rules/<branch>/*.json` 是语义查表，给 prompt 引用。例如 `rules/bazi/ten_gods_meaning.json` 是十神 → 中文描述的映射。

### 加新的查表

例：你想加"纳音五行"查表给八字用：

```bash
# 1. 新建 JSON
cat > rules/bazi/nayin.json << 'EOF'
{
  "甲子": {"五行": "金", "纳音": "海中金"},
  ...
}
EOF

# 2. 在 prompt/bazi.md 的"分析框架"里引用
# "纳音五行：查 rules/bazi/nayin.json"

# 3. 让 prompt 知道这张表存在
```

### 改现有的查表

直接改 `rules/<branch>/*.json` 的内容，保持 schema 一致即可。

---

## 加新方法（如紫微 / 数字命理）

假设你想加紫微斗数：

```bash
# 1. 写引擎
mkdir -p engine
# engine/ziwei_engine.py
# engine/run_ziwei.sh

# 2. 写 rules
mkdir -p rules/ziwei
# rules/ziwei/star_meaning.json
# rules/ziwei/palace_meaning.json

# 3. 写 prompt
# prompt/ziwei.md

# 4. 写样例
mkdir -p examples/ziwei
# examples/ziwei/sample_input.json
# examples/ziwei/sample_facts.json

# 5. 改 SKILL.md
# 在"第 1 步：方法选择"加 "D. 紫微（ziwei）"
# 在"第 4 步：执行流程"加 "分支 D：紫微"
```

工作量不算小，但因为有现成的 bazi / astrology / synastry 三个完整范例，照搬结构就行。

---

## 改 SKILL.md

`SKILL.md` 是入口契约。**顶部 frontmatter（name / description）尽量别动**——那是给 Claude Code 自动派发用的；改了可能影响识别。

中间流程（启动问询、统一输入、执行流程、输出合同）可以根据你加的新方法 / 改的工作流去调。

---

## 改 engine（不推荐，但万一你想）

`engine/` 是 Layer 1，确定性计算。改它的风险：
- 同一个生辰，前后可能算出不同四柱 / 行星位置
- 用户失去信任

如果**你必须**改，下面这些场景是合理的：

| 场景 | 合理的改法 |
|---|---|
| 想加真太阳时修正 | 在 engine 入口处，按经度先把 `birth_datetime` 偏移 `(lon - 120) * 4` 分钟 |
| 想换宫制（Whole Sign / Equal） | `engine/astrology_engine.py` 里 `resolve_house_system` 函数 |
| 想加木星 / 海王过运 | 新写一个 `engine/transit_engine.py`，参考 `synastry_engine.py` 的结构 |

**不该改**的：节气划分、四柱算法、十神映射、相位 orb 默认值——这些是命理 / 占星界的标准约定，改了不再是同一份"事实"。

---

## 工程基本盘

### 测试你的改动

```bash
# 改 prompt 之后，跑一次完整流程
bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/facts.json

# 在 Claude Code 里说"用样例数据帮我看下星盘"，看输出
```

### 不要 commit 的东西

`.gitignore` 已经包含：
- `__pycache__/` / `*.pyc`
- `/tmp/` 临时文件
- 个人 facts 输出（如果有）

### 提交前的自检

如果你打算 PR 回上游或开源你的 fork：

- 跑一遍 `bash scripts/install.sh` 确认装得通
- 跑一遍 `bash engine/run_*.sh` 全部三个样例确认 engine 没坏
- 检查 prompt 里有没有泄露你的个人数据

---

## 一个好习惯：给你的 fork 加 `MY_NOTES.md`

把你为什么这样改、改了什么写进 `MY_NOTES.md`（.gitignore 已忽略）。三个月后回来看，你会感谢自己。

---

## 我的 prompt 烂掉了怎么办

```bash
# 退到 git 历史
git checkout HEAD -- prompt/bazi.md

# 或者从 GitHub 上重拉
curl -fsSL https://raw.githubusercontent.com/<upstream>/destiny-reading/main/prompt/bazi.md > prompt/bazi.md
```

---

## 还有问题？

- 整体架构：见 [README.md](README.md)
- 安装：见 [INSTALL.md](INSTALL.md)
- AI 工具引导：见 [AGENTS.md](AGENTS.md)
