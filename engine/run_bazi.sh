#!/usr/bin/env bash
# 包装脚本：把 input.json 喂进引擎，输出 facts.json
#
# 用法:
#   ./engine/run.sh examples/sample_input.json examples/sample_facts.json
#
# input.json 字段:
#   birth_datetime         ISO 带时区, 例 "1990-01-01T12:00:00+08:00"
#   gender                 "male" | "female"
#   dayun_count            可选, 默认 8
#   liunian_start_year     可选, 默认当前年-2
#   liunian_count          可选, 默认 5

set -euo pipefail

IN="${1:-}"
OUT="${2:-}"

if [[ -z "$IN" || -z "$OUT" ]]; then
  echo "usage: $0 <input.json> <output.json>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 用 python 解 JSON, 再拼 CLI 参数
python3 - "$IN" "$OUT" "$SCRIPT_DIR" <<'PY'
import json, sys, subprocess, datetime
inp, out, sd = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(inp, "r", encoding="utf-8"))

birth   = data["birth_datetime"]
gender  = data["gender"]
dayun   = str(data.get("dayun_count", 8))
ln_cnt  = str(data.get("liunian_count", 5))
ln_year = str(data.get("liunian_start_year", datetime.date.today().year - 2))

subprocess.run([
    sys.executable,
    f"{sd}/bazi_skill_engine.py",
    "--birth-datetime", birth,
    "--gender", gender,
    "--dayun-count", dayun,
    "--liunian-start-year", ln_year,
    "--liunian-count", ln_cnt,
    "--output", out,
], check=True)
print(f"[ok] facts written to {out}")
PY
