#!/usr/bin/env bash
set -euo pipefail

# === 全局设置 ===
GFWLIST_URL="https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURRENT_BEIJING_TIME=$(TZ="Asia/Shanghai" date +"%a, %d %b %Y %H:%M:%S %z")

RAW_FILE=$(mktemp -t GFWLIST_RAW.XXXXXX)
DECODED_FILE=$(mktemp -t GFWLIST_DECODED.XXXXXX)
MERGED_FILE=$(mktemp -t GFWLIST_MERGED.XXXXXX)

trap 'rm -f "$RAW_FILE" "$DECODED_FILE" "$MERGED_FILE"' EXIT

# === 函数定义 ===
usage() {
    echo "用法: $0 <CUSTOM_FILE> <OUTPUT_FILE>"
    exit 1
}

check_file_exists() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo "错误: 文件不存在: $file_path"
        exit 1
    fi
}

download_gfwlist() {
    echo "开始下载 gfwlist 文件..."
    if ! curl -fsSL --retry 3 "$GFWLIST_URL" -o "$RAW_FILE"; then
        echo "下载失败，退出"
        exit 1
    fi
    echo "下载完成：$(basename "$RAW_FILE")"
}

validate_checksum() {
    echo "验证 gfwlist 文件 checksum..."
    "$SCRIPT_DIR/validateChecksum.sh" "$RAW_FILE"
}

decode_gfwlist() {
    echo "解码 gfwlist 文件..."
    base64 -d "$RAW_FILE" > "$DECODED_FILE"
}

update_metadata() {
    echo "更新 Last Modified 时间..."
    sed -i '/^! Checksum:/d' "$DECODED_FILE"
    sed -i "s/^! Last Modified:.*/! Last Modified: $CURRENT_BEIJING_TIME/" "$DECODED_FILE"
}

merge_custom_rules() {
    local custom_file="$1"
    echo "合并自定义规则..."
    {
        sed '$d' "$DECODED_FILE"
        echo
        sed -e :a -e '/^[[:space:]]*$/{$d;N;ba;}' -e '$a\' "$custom_file"
        echo
        tail -n1 "$DECODED_FILE"
    } > "$MERGED_FILE"
}

compute_and_insert_checksum() {
    echo "计算并插入新的 checksum..."
    local checksum
    checksum=$(tr -d '\r' < "$MERGED_FILE" \
        | sed ':a;N;$!ba;s/\n\+/\n/g' \
        | md5sum \
        | awk '{print $1}' \
        | xxd -r -p \
        | base64 \
        | tr -d '=')
    sed -i "2i ! Checksum: $checksum" "$MERGED_FILE"
}

encode_output() {
    local output_file="$1"
    echo "生成最终 Base64 文件..."
    # 确保输出目录存在
    mkdir -p "$(dirname "$output_file")"
    # 检查并清空或创建输出文件
    if [[ -f "$output_file" ]]; then
        echo "检测到已有输出文件，清空内容: $output_file"
        : > "$output_file"
    else
        echo "输出文件不存在，创建新文件: $output_file"
        touch "$output_file"
    fi
    base64 "$MERGED_FILE" > "$output_file"
    echo "处理完成，输出文件: $output_file"
}

# === 主函数 ===
main() {
    if [[ $# -ne 2 ]]; then
        usage
    fi

    local custom_file="$1"
    local output_file="$2"

    check_file_exists "$custom_file"
    download_gfwlist
    validate_checksum
    decode_gfwlist
    update_metadata
    merge_custom_rules "$custom_file"
    compute_and_insert_checksum
    encode_output "$output_file"
}

# === 执行入口 ===
main "$@"