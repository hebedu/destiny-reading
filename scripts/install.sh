#!/usr/bin/env bash
# destiny-reading · 一键安装脚本
#
# 这个脚本会做下面这些事：
#   1. 检查 Python / pip 是否可用
#   2. 安装 pyswisseph 依赖
#   3. 检查 Chiron 星历文件 (engine/seas_18.se1)，缺了就下载
#   4. 跑一遍样例验证 engine 能用
#   5. 询问你要不要把这个 skill 注册到 Claude Code (~/.claude/skills/)
#   6. 打印"接下来怎么用"
#
# 用法:
#   bash scripts/install.sh
#
# 全默认无交互:
#   bash scripts/install.sh --yes

set -euo pipefail

# ----- 解析参数 -----
AUTO_YES=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y) AUTO_YES=1 ;;
    --help|-h)
      sed -n '2,18p' "$0"
      exit 0
      ;;
  esac
done

# ----- 颜色辅助 -----
if [ -t 1 ]; then
  C_GREEN='\033[32m'; C_BLUE='\033[34m'; C_YELLOW='\033[33m'; C_RED='\033[31m'; C_RESET='\033[0m'
else
  C_GREEN=''; C_BLUE=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi
say()  { echo -e "${C_BLUE}[install]${C_RESET} $*"; }
ok()   { echo -e "${C_GREEN}[ok]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[warn]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[error]${C_RESET} $*" >&2; }

ask() {
  # ask "提示" "默认值"
  if [ "$AUTO_YES" = "1" ]; then
    echo "$2"
    return
  fi
  local prompt="$1"; local default="$2"
  read -r -p "$prompt [$default] " reply </dev/tty || reply=""
  echo "${reply:-$default}"
}

# ----- 找到项目根目录 -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo
say "destiny-reading 安装器"
say "项目目录: $PROJECT_ROOT"
echo

# ----- 1. 检查 Python -----
say "Step 1/5 · 检查 Python"
if ! command -v python3 >/dev/null 2>&1; then
  err "找不到 python3。请先装 Python 3.9+ (https://www.python.org/)"
  exit 1
fi
PY_VERSION="$(python3 --version | awk '{print $2}')"
ok "Python $PY_VERSION"

if ! python3 -c "import pip" >/dev/null 2>&1; then
  err "你的 python3 没装 pip，请先装 pip (python3 -m ensurepip --upgrade)"
  exit 1
fi
echo

# ----- 2. 装 pyswisseph -----
say "Step 2/5 · 安装 pyswisseph (瑞士星历)"
if python3 -c "import swisseph" >/dev/null 2>&1; then
  ok "swisseph 已装"
else
  say "正在 pip install pyswisseph（首次装会编译 C 扩展，可能要 1-2 分钟）..."
  pip3 install --user -r "$PROJECT_ROOT/engine/requirements.txt" --quiet
  python3 -c "import swisseph" >/dev/null 2>&1 || { err "装失败，请手动跑: pip3 install pyswisseph"; exit 1; }
  ok "pyswisseph 装好"
fi
echo

# ----- 3. 检查 Chiron 星历 -----
say "Step 3/5 · 检查 Chiron 星历文件"
SEAS="$PROJECT_ROOT/engine/seas_18.se1"
if [ -f "$SEAS" ] && [ "$(wc -c < "$SEAS" | tr -d ' ')" -gt 100000 ]; then
  ok "seas_18.se1 已就位 ($(du -h "$SEAS" | awk '{print $1}'))"
else
  warn "seas_18.se1 不在 / 文件太小，开始下载..."
  if curl -fsSL -o "$SEAS" "https://raw.githubusercontent.com/aloistr/swisseph/master/ephe/seas_18.se1"; then
    ok "下载完成 ($(du -h "$SEAS" | awk '{print $1}'))"
  else
    err "下载失败。请手动下载 seas_18.se1 放到 engine/ 目录:"
    err "  https://github.com/aloistr/swisseph/tree/master/ephe"
    exit 1
  fi
fi
echo

# ----- 4. 跑样例验证 -----
say "Step 4/5 · 跑一份样例验证 engine"
TMP_OUT="$(mktemp /tmp/destiny_install_verify_XXXXXX.json)"
if bash "$PROJECT_ROOT/engine/run_astrology.sh" \
     "$PROJECT_ROOT/examples/astrology/sample_input.json" \
     "$TMP_OUT" >/dev/null 2>&1; then
  ok "astrology engine 正常 (输出 $(wc -l < "$TMP_OUT" | tr -d ' ') 行 JSON)"
  rm -f "$TMP_OUT"
else
  err "样例跑失败，请手动检查："
  err "  bash $PROJECT_ROOT/engine/run_astrology.sh $PROJECT_ROOT/examples/astrology/sample_input.json /tmp/out.json"
  exit 1
fi
echo

# ----- 5. 注册到 Claude Code -----
say "Step 5/5 · 注册到 Claude Code（可选）"

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
TARGET_LINK="$CLAUDE_SKILLS_DIR/destiny-reading"

if [ -e "$TARGET_LINK" ] || [ -L "$TARGET_LINK" ]; then
  warn "$TARGET_LINK 已存在（之前装过？）"
  REGISTER=0
else
  ANSWER="$(ask "把这个目录软链到 ~/.claude/skills/destiny-reading 让 Claude Code 自动发现？(y/n)" "y")"
  case "$ANSWER" in
    y|Y|yes|YES) REGISTER=1 ;;
    *) REGISTER=0 ;;
  esac
fi

if [ "$REGISTER" = "1" ]; then
  mkdir -p "$CLAUDE_SKILLS_DIR"
  ln -sf "$PROJECT_ROOT" "$TARGET_LINK"
  ok "已软链: $TARGET_LINK -> $PROJECT_ROOT"
  ok "Claude Code 重启后会自动识别 destiny-reading skill"
else
  warn "跳过 Claude Code 注册"
fi
echo

# ----- 完成 -----
echo -e "${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo -e "${C_GREEN}✓ 安装完成${C_RESET}"
echo -e "${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
echo
echo "接下来可以："
echo
if [ "$REGISTER" = "1" ]; then
  echo "  1. ${C_BLUE}重启 Claude Code${C_RESET}（让它发现新 skill）"
  echo "  2. 对它说: ${C_YELLOW}\"帮我算下八字 / 看下星盘 / 看合盘\"${C_RESET}"
  echo "     Claude 会引导你输入生辰，然后自动调本目录的引擎+提示词"
  echo
fi
echo "  • 命令行直接用引擎（不依赖 AI 工具）:"
echo "      bash engine/run_bazi.sh examples/bazi/sample_input.json /tmp/out.json"
echo "      cat /tmp/out.json"
echo
echo "  • 想换成自己的解读提示词：看 ${C_YELLOW}CUSTOMIZE.md${C_RESET}"
echo "  • 想懂分层架构：看 ${C_YELLOW}README.md${C_RESET}"
echo
