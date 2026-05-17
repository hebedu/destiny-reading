# INSTALL.md · 安装指南

`destiny-reading` 是一个 **AI 工具无关** 的项目——它能被 Claude Code 当作 skill 自动派发，也能被 Codex / Cursor / Cline / Aider 这类工具读，还能纯命令行用。

下面按你的环境分别讲怎么装。

---

## 通用前置

不管用什么 AI 工具，先做完这三步：

```bash
# 1. 拉代码
git clone https://github.com/<your-username>/destiny-reading.git
cd destiny-reading

# 2. 装依赖（pyswisseph + 自动下 Chiron 星历）
bash scripts/install.sh

# 3. 跑一次样例验证
bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/out.json
```

`install.sh` 会问你要不要软链到 `~/.claude/skills/destiny-reading/`——这是给 Claude Code 用的。如果你不用 Claude Code，回答 `n` 跳过即可。

---

## Path A · Claude Code

最丝滑的路径。

### 步骤

```bash
git clone https://github.com/<your-username>/destiny-reading.git
cd destiny-reading
bash scripts/install.sh   # 默认会软链到 ~/.claude/skills/destiny-reading
```

### 验证

```bash
ls -la ~/.claude/skills/destiny-reading
# 应该看到一个软链指向你 clone 的目录
```

### 使用

1. **重启 Claude Code**（让它扫描新 skill）
2. 在任何对话里说："帮我看下八字" / "算下星盘" / "看合盘"
3. Claude Code 会发现这个 skill 的 `SKILL.md` 的 frontmatter 关键词，自动派发到本 skill
4. Claude 会按 SKILL.md 的"启动问询"流程跟你对话收集生辰

### 如果不工作

- 确认 `SKILL.md` 顶部有 `name: destiny-reading` 的 frontmatter
- 重启 Claude Code 进程
- 看 Claude Code 的 `/skills` 列表里有没有 `destiny-reading`

---

## Path B · Codex / Cursor / Cline / Aider 等

这些工具大多没有"skill 自动派发"机制，但都能读 markdown + 跑 shell——已经够用。

### 步骤

```bash
git clone https://github.com/<your-username>/destiny-reading.git
cd destiny-reading
bash scripts/install.sh   # 软链问题答 n（你不需要 ~/.claude/skills）
```

### 使用

1. 用你的工具（Codex / Cursor / Cline / Aider）打开 `destiny-reading/` 目录
2. **关键**：项目根有 `AGENTS.md`——大多数 AI 工具能自动读这份当指令
3. 跟 AI 说："帮我看下八字 / 看合盘"
4. AI 会读 `AGENTS.md` → 读 `SKILL.md` → 按流程跟你对话收集生辰 → 跑 `engine/*.sh` → 按 `prompt/*.md` 写解读

如果你的工具不自动读 `AGENTS.md`，**手动**把它的内容粘到工具的 system prompt / instructions 里。

### 工具特定提示

| 工具 | 注意 |
|---|---|
| **Codex** | 自动读 `AGENTS.md`，不用配置 |
| **Cursor** | 自动读 `.cursorrules`（没有）；可以创建 `.cursorrules` 软链到 `AGENTS.md`：`ln -s AGENTS.md .cursorrules` |
| **Cline / Continue** | 一般有 "custom instructions" 设置——把 `AGENTS.md` 内容贴进去 |
| **Aider** | 用 `--read AGENTS.md` 启动 |

---

## Path C · 命令行（不依赖 AI 工具）

如果你只想要 engine 计算 facts、自己处理后续：

### 步骤

```bash
git clone https://github.com/<your-username>/destiny-reading.git
cd destiny-reading
bash scripts/install.sh   # 软链问题答 n
```

### 单独调用

**八字**：
```bash
cat > /tmp/in.json << 'EOF'
{
  "birth_datetime": "1990-01-01T12:00:00+08:00",
  "gender": "female",
  "dayun_count": 8,
  "liunian_start_year": 2024,
  "liunian_count": 5
}
EOF
bash engine/run_bazi.sh /tmp/in.json /tmp/bazi.json
cat /tmp/bazi.json
```

**星座**：
```bash
cat > /tmp/in.json << 'EOF'
{
  "input": {
    "birth_datetime": "1990-01-01 12:00:00",
    "location": {
      "label": "Beijing, China",
      "lat": 39.9042,
      "lon": 116.4074,
      "timezone": "Asia/Shanghai"
    },
    "house_system": "Placidus",
    "zodiac_type": "Tropical"
  }
}
EOF
bash engine/run_astrology.sh /tmp/in.json /tmp/astro.json
```

**合盘**（先算两个人的本命，再合）：
```bash
bash engine/run_astrology.sh person_a_input.json /tmp/a_facts.json
bash engine/run_astrology.sh person_b_input.json /tmp/b_facts.json
bash engine/run_synastry.sh /tmp/a_facts.json /tmp/b_facts.json person_a person_b /tmp/syn.json
```

### 输出 schema

每种 engine 的输出 JSON 字段说明在 `prompt/*.md` 顶部的"A. 输入预备 · engine 数据映射表"——那是写给 LLM 用的，对你查字段也一样有用。

---

## 故障排查

### `import swisseph` 失败

```bash
pip3 install pyswisseph
# 或者
pip3 install --user pyswisseph
```

如果 mac M1 / M2 编译失败，先装好 Xcode Command Line Tools：
```bash
xcode-select --install
```

### Chiron 算不出来 (`seas_18.se1 not found`)

```bash
curl -fsSL -o engine/seas_18.se1 \
  https://raw.githubusercontent.com/aloistr/swisseph/master/ephe/seas_18.se1
```

### `~/.claude/skills/destiny-reading` 软链不工作

```bash
# 先删旧的（如果有）
rm -f ~/.claude/skills/destiny-reading

# 重新软链（注意要用绝对路径）
ln -sf "$(pwd)" ~/.claude/skills/destiny-reading

# 验证
ls -la ~/.claude/skills/destiny-reading
```

### Claude Code 看不到这个 skill

- 确认 `SKILL.md` 顶部 frontmatter 完整
- 重启 Claude Code 进程
- 跑 `/skills` 看列表

---

## 卸载

```bash
# 取消 Claude Code 注册
rm -f ~/.claude/skills/destiny-reading

# 删整个项目
rm -rf destiny-reading

# pyswisseph 是公共依赖，是否卸载看你
pip3 uninstall pyswisseph
```
