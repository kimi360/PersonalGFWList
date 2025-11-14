#!/usr/bin/env bash
set -euo pipefail

# === 全局设置 ===
DECODED_TMP=$(mktemp -t GFWLIST_DECODED.XXXXXX)
trap 'rm -f "$DECODED_TMP"' EXIT

# === 函数定义 ===

# 打印错误信息并退出
error_exit() {
  echo "错误: $1" >&2
  exit "${2:-1}"
}

# Base64 解码文件到临时文件
decode_file() {
  local input_file="$1"

  if ! base64 --decode "$input_file" > "$DECODED_TMP" 2>/dev/null \
    && ! base64 -D "$input_file" > "$DECODED_TMP" 2>/dev/null; then
    error_exit "Base64 解码失败"
  fi
}

# 提取文件中的期望 Checksum
extract_expected_checksum() {
  local checksum_line
  checksum_line=$(grep -m1 '^! Checksum:' "$DECODED_TMP" || true)
  if [[ -z "$checksum_line" ]]; then
    error_exit "未找到 '! Checksum:' 行"
  fi

  local checksum
  checksum=$(awk '/^! Checksum:/ {print $3; exit}' "$DECODED_TMP")
  if [[ -z "$checksum" ]]; then
    error_exit "Checksum 提取失败"
  fi

  echo "$checksum"
}

# 计算实际 Checksum
calculate_actual_checksum() {
  local md5_hex actual_checksum

  md5_hex=$(sed '/^! Checksum:/d' "$DECODED_TMP" \
    | tr -d '\r' \
    | sed ':a;N;$!ba;s/\n\+/\n/g' \
    | md5sum | awk '{print $1}')

  if command -v xxd >/dev/null 2>&1; then
    actual_checksum=$(printf "%s" "$md5_hex" | xxd -r -p | base64 | tr -d '=')
  elif command -v perl >/dev/null 2>&1; then
    actual_checksum=$(printf "%s" "$md5_hex" | perl -0777 -ne 'print pack("H*", $_)' | base64 | tr -d '=')
  else
    error_exit "缺少 xxd 或 perl 命令，无法转换哈希值为二进制"
  fi

  echo "$actual_checksum"
}

# 比较两者的 Checksum
compare_checksums() {
  local expected="$1"
  local actual="$2"

  if [[ "$actual" == "$expected" ]]; then
    echo "Checksum 匹配成功"
    return 0
  else
    echo "Checksum 匹配失败"
    echo "  期望值: $expected"
    echo "  实际值: $actual"
    return 2
  fi
}

# === 主函数 ===
main() {
  local input_file="${1:-}"
  if [[ -z "$input_file" ]]; then
    echo "用法: $0 <gfwlist-file>"
    exit 1
  fi

  if [[ ! -f "$input_file" ]]; then
    error_exit "文件不存在: $input_file"
  fi

  echo "开始验证文件 $(basename "$input_file") ..."
  decode_file "$input_file"

  local expected_checksum actual_checksum
  expected_checksum=$(extract_expected_checksum)
  actual_checksum=$(calculate_actual_checksum)

  compare_checksums "$expected_checksum" "$actual_checksum"
}

# === 执行入口 ===
main "$@"