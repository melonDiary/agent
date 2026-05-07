#!/bin/bash

# Shadowrocket 规则文件去重脚本
# 用法: ./dedupe.sh [目录路径]
# 默认处理当前目录下所有 .list 文件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取目录参数，默认当前目录
DIR="${1:-.}"

# 检查目录是否存在
if [ ! -d "$DIR" ]; then
    echo -e "${RED}错误: 目录 '$DIR' 不存在${NC}"
    exit 1
fi

cd "$DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Shadowrocket 规则文件去重工具${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "工作目录: ${YELLOW}$(pwd)${NC}"
echo ""

# 统计变量
total_before=0
total_after=0
processed=0
changed=0

# 遍历所有 .list 文件
for file in *.list; do
    # 跳过不存在的文件（当没有匹配时）
    [ -e "$file" ] || continue
    
    before=$(wc -l < "$file" | awk '{print $1}')
    
    # 备份原文件
    cp "$file" "${file}.tmp"
    
    # 去重逻辑：
    # 1. 保留以 # 开头的注释行（文件头部的注释块）
    # 2. 保留空行
    # 3. 规则行去重（保留首次出现）
    awk '
    BEGIN {
        in_header = 1
    }
    {
        # 检测是否在文件头注释块中
        if (in_header) {
            if (/^#/) {
                print
                next
            } else if (/^[[:space:]]*$/) {
                next
            } else {
                in_header = 0
            }
        }
        
        # 非注释行：去重
        if (!seen[$0]++) print
    }
    ' "${file}.tmp" > "$file"
    
    # 删除临时文件
    rm "${file}.tmp"
    
    after=$(wc -l < "$file" | awk '{print $1}')
    diff=$((before - after))
    
    total_before=$((total_before + before))
    total_after=$((total_after + after))
    processed=$((processed + 1))
    
    if [ $diff -gt 0 ]; then
        changed=$((changed + 1))
        printf "  ${GREEN}%-30s${NC} %6d -> %6d ${YELLOW}(removed %d)${NC}\n" "$file" "$before" "$after" "$diff"
    fi
done

echo ""
echo -e "${BLUE}----------------------------------------${NC}"
echo -e "处理完成!"
echo -e "  文件总数: ${processed}"
echo -e "  有变化的: ${changed}"
echo -e "  原始行数: ${total_before}"
echo -e "  去重后数: ${total_after}"
echo -e "  去除重复: ${GREEN}$((total_before - total_after))${NC}"
echo -e "${BLUE}========================================${NC}"
