#!/usr/bin/env bash
# 包装脚本：把 input.json 喂进西方占星引擎，输出 facts.json
#
# 用法:
#   ./engine/run_astrology.sh examples/astrology/sample_input.json /tmp/facts.json
#
# input.json 字段（参考 examples/astrology/sample_input.json）:
#   input.birth_datetime    本地时间字符串, 例 "1990-01-01 12:00:00"
#   input.location.lat      纬度
#   input.location.lon      经度
#   input.location.timezone IANA, 例 "Asia/Shanghai"
#   input.house_system      默认 "Placidus"
#   input.zodiac_type       默认 "Tropical"
#   input.language          默认 "zh-CN"

set -euo pipefail

IN="${1:-}"
OUT="${2:-}"

if [[ -z "$IN" || -z "$OUT" ]]; then
  echo "usage: $0 <input.json> <output.json>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$SCRIPT_DIR/astrology_engine.py" --input-file "$IN" --output-file "$OUT"
echo "[ok] facts written to $OUT"
