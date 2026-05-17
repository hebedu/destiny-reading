# CLAUDE.md · Claude Code 专用引导

> 这份文件 Claude Code 会自动加载到当前项目的上下文。
> 内容跟 `AGENTS.md` 大部分重叠（那份是"任何 AI 助手"通用版）；这里只补 Claude Code 特有的小动作。

---

## 第一次进项目，请按这个顺序

1. **检查 `~/.claude/skills/destiny-reading` 是否软链到当前目录**
   - 没有 → 提示用户跑 `bash scripts/install.sh`
   - 有 → 提示用户"已注册为 Claude Code skill，重启 Claude Code 后说'帮我看八字 / 星盘 / 合盘'即可自动调用"

2. **检查 pyswisseph 和 seas_18.se1**
   - `python3 -c "import swisseph"` 不通过 → 装依赖
   - `engine/seas_18.se1` 缺失 / 太小 → 跑 install.sh 会自动下

3. **跑一次样例验证**
   - `bash engine/run_astrology.sh examples/astrology/sample_input.json /tmp/out.json`

---

## 你和这个 skill 的关系

- 当用户**没启用 destiny-reading skill** 时：你在这个项目里就是普通编程助手，帮用户改 prompt、改 engine、写文档、做工程
- 当用户**说"帮我算八字 / 星盘 / 合盘"** 且 skill 已注册：你应该走 `SKILL.md` 的"启动问询"流程，跟用户对话收集生辰，调 engine，按 prompt 生成解读

---

## 详细引导规则

完整内容见 `AGENTS.md`——那份是写给所有 AI 助手通用的，对你也适用。

---

## 与 Claude Code memory 系统的关系

这份文件只在**当前项目内**生效。
用户全局 `~/.claude/memory/MEMORY.md` 里的偏好不会被你这份覆盖。
两者并存——全局的"用户偏好"+ 本项目的"工程约束"= 完整上下文。
