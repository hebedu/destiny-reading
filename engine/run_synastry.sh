#!/usr/bin/env bash
# 包装脚本：吃两个人的本命 facts.json，吐 synastry + composite facts.json
#
# 用法:
#   ./engine/run_synastry.sh <A_facts.json> <B_facts.json> <A_name> <B_name> <output.json>
#
# 例:
#   bash engine/run_synastry.sh \
#     examples/astrology/sample_facts.json \
#     /tmp/yang_facts.json \
#     person_a person_b \
#     examples/synastry/sample_facts.json
#
# 前置: 两个人的本命 facts.json 都应已通过 engine/run_astrology.sh 算好。

set -euo pipefail

if [[ "$#" -ne 5 ]]; then
  echo "usage: $0 <A_facts.json> <B_facts.json> <A_name> <B_name> <output.json>" >&2
  exit 1
fi

A_FACTS="$1"
B_FACTS="$2"
A_NAME="$3"
B_NAME="$4"
OUT="$5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 "$SCRIPT_DIR/synastry_engine.py" \
  --person-a "$A_FACTS" \
  --person-b "$B_FACTS" \
  --person-a-name "$A_NAME" \
  --person-b-name "$B_NAME" \
  --output-file "$OUT"
